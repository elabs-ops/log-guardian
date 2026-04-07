#!/bin/bash

# Initialisation de l'environnement
BASE_DIR=$(dirname "$(readlink -f "$0")")
cd "$BASE_DIR"
# echo $PWD


# Import des modules
. "$BASE_DIR/lib/utils.lib.sh"
. "$BASE_DIR/lib/core.lib.sh"
. "$BASE_DIR/lib/firewall.lib.sh"
. "$BASE_DIR/lib/tests.lib.sh"


# Création des dossiers et fichier requis
ensure_directories_exist

# Gestion des arguments
case "$1" in
    --mock)
        mock_ssh_attacks ;;
    --flush-logs)
    	ensure_root_permission
   		display_info "Nettoyage des journaux système..."
        flush_system_logs ;;
    --stats)
    	stats=$(count_occurences_by_ip)
    	if [[ -z "$stats" ]]; then
    		display_info "Journaux vides - Aucune connexion ssh"
    	else
    		display_info "Statistiques des tentatives du jour (${RED}seuil: $BAN_THRESHOLD)${RESET}) :"
    		echo "$stats"
    	fi ;;
    --parsed-raw)
    	display_info "Logs bruts extraits (Date + IP) :"
    	parse_raw_logs_with_timestamp ;;
    --malicious)
    	malicious=$(filter_ips_by_threshold)
    	if [[ -n "$malicious" ]]; then
    		display_info "IP dépassant le seuil de connexion (seuil: $BAN_THRESHOLD) :"
    		echo "$malicious"
    	else
    		display_success "Aucune IP malicieuse détectée."
    	fi ;;
    --update)
    	ensure_not_root_permission
    	require_runtime_file "$BANNED_IPS_DB"

        # ÉTAPE 1 : On récupère les IPs malveillantes via core.lib
        targets_to_ban=$(identify_malicious_ips)

   		display_info "Mise à jour des protections..."

        # ÉTAPE 2 : On vérifie s'il y a des ips à bannir
        if [[ -n "$targets_to_ban" ]]; then
        	display_info "Nouvelles menaces détectées. Action en cours..."

        	# ÉTAPE 3 : On envoie ces IPs à firewall.lib pour persistance
        	persist_banned_ips "$targets_to_ban"
        else	
        	display_success "Aucune nouvelle menace identifiée."
        fi ;;
    --apply-bans)
    	ensure_root_permission
    	require_runtime_file "$BANNED_IPS_DB"
    	# ÉTAPE 4 : On applique les règles iptables
        if [[ -s "$BANNED_IPS_DB" ]]; then
        	enforce_firewall_rules
        	display_success "Règles iptables mises à jour."
    		exit 0
        else
        	display_info "Fichier non trouvé. Pas de règle à appliquer"
        fi
    	;;
    --report)
    	ensure_not_root_permission
        generate_security_report | tee "${APP_VAR_REPORTS_DIR}/security_report_$(date +%F).txt"
        ;;
    --repair)
        ensure_not_root_permission
        ensure_directories_exist ;;
    --firewall-flush)
    	ensure_root_permission
        flush_firewall_rules ;;
    --firewall-list)
    	ensure_root_permission
        get_firewall_rules ;;
    --firewall-status)
    	ensure_root_permission
    	input=$(iptables -S INPUT | grep -c " -j DROP")
    	echo "IPs réellement bloquées : $input"
    	;;
    *)
        echo "Usage: $0 {--stats|--parsed-raw|--malicious|--update|--apply-bans|--report|--repair|--firewall-flush|--firewall-list|firewall-status|--mock|--flush-logs}"
        exit 1 ;;
esac