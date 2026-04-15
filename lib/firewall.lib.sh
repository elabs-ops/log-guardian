#!/bin/bash

#set -e

# Créer ou mettre à jour le fichier de sauvegarde des ip à bannir
# Accepte 1 argument new_ips : les ips à ajouter au fichier
persist_banned_ips(){
	local new_ips="$1"
	if [[ -z "$new_ips" ]]; then
		display_info "Aucune nouvelle IP à ajouter à la base de données."
		return 0
	fi

	{ cat "$BANNED_IPS_DB"
	  echo "$new_ips" 
	} | sort -u > "${BANNED_IPS_DB}.tmp" && mv "${BANNED_IPS_DB}.tmp" "$BANNED_IPS_DB"

	display_success "Base de données des bannissements mise à jour."
}

# Ajouter les ips (règles) au pare feu 
enforce_firewall_rules(){
	while read -r ip; do
		# si la règle n'existe pas on ajoute
		if ! iptables -C INPUT -s "$ip" -j DROP &>/dev/null; then
			iptables -A INPUT -s "$ip" -j DROP
			display_success "IP $ip ajoutée au pare feu"
			log_event "BANNED: $ip"	
		fi
	done < "$BANNED_IPS_DB"
}

# Afficher les règles INPUT
get_firewall_rules(){
	iptables -L INPUT -n -v --line-numbers
}

# Supprimer les règles INPUT
flush_firewall_rules(){
	iptables -F INPUT
	display_info "Pare-feu réinitialisé"
	log_event "FLUSH: Toutes les règles INPUT supprimées."
}

generate_security_report(){
	local date_now=$(date '+%d/%m/%Y')
	local detected_count=$(parse_ips_from_logs | sort -u | wc -l)
	local malicious_count=$(filter_ips_by_threshold | wc -l)
	local file_bans=$(wc -l < "$BANNED_IPS_DB" 2>/dev/null || echo 0)

	echo -e "\n=== RAPPORT DE SÉCURITÉ - $date_now ==="
    echo "• IPs détectées aujourd'hui : $detected_count"
    echo "• IPs suspectes détectées aujourd'hui : $malicious_count"
    echo "• IPs actuellement bloquées en base (.db): $file_bans"
    echo "• IPs réellement bloquées (iptables) : exécutez 'sudo logguardian --firewall-status'"
    echo "=========================================="
}