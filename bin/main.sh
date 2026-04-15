#!/bin/bash
#set -eo pipefail

# Initialisation de l'environnement
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
PROJECT_ROOT=$(dirname "$SCRIPT_DIR")
cd "$SCRIPT_DIR"
# echo $PWD


# Import des modules
. "$PROJECT_ROOT/lib/utils.lib.sh"
. "$PROJECT_ROOT/lib/core.lib.sh"
. "$PROJECT_ROOT/lib/firewall.lib.sh"
. "$PROJECT_ROOT/lib/tests.lib.sh"

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
        ensure_local_ips_whitelisted

        targets_to_ban=$(identify_malicious_ips)

   		display_info "Mise à jour des protections..."

        if [[ -n "$targets_to_ban" ]]; then
        	display_info "Nouvelles menaces détectées. Action en cours..."

        	persist_banned_ips "$targets_to_ban"
        else	
        	display_success "Aucune nouvelle menace identifiée."
        fi ;;
    --apply-bans)
    	#ensure_root_permission
        # Si non root, utilisation de sudo (vérifier sudoers)
        if [[ "$EUID" -ne 0 ]]; then
            display_info "Élévation des privilèges via sudo..."
            exec sudo "$0" "$@"
        fi
    	require_runtime_file "$BANNED_IPS_DB"
        if [[ -s "$BANNED_IPS_DB" ]]; then
        	enforce_firewall_rules
        	display_success "Règles iptables mises à jour."
    		exit 0
        else
        	display_info "Fichier vide. Pas de règle à appliquer"
        fi
    	;;
    --report)
    	ensure_not_root_permission
        generate_security_report | tee "${APP_VAR_REPORTS_DIR}/security_report_$(date +%F).txt"
        ;;
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
    --repair)
    	ensure_not_root_permission
    	ensure_directories_exist ;;
    *)
        echo "Usage: $0 {--stats|--parsed-raw|--malicious|--update|--apply-bans|--report|--repair|--firewall-flush|--firewall-list|firewall-status|--mock|--flush-logs}"
        exit 1 ;;
esac