#!/bin/bash

# --- LOGIQUE D'EXTRACTION  ET SECURITÉ ---
# Format : Mar 17 01:05:33 hostname sshd[21654]: Failed password for root from 192.168.1.100 port 54321 ssh2


# Récupère les échecs de connexion du jour (--since today)
fetch_failed_ssh_logs(){
    journalctl -t sshd --since today | grep -i "failed password"
}

# Extrait les adresses IP uniquement
parse_ips_from_logs(){
    fetch_failed_ssh_logs | awk -v ip="" '{ 
        for(i=1; i<=NF; i++) { if($i == "from") ip=$(i+1); }
        if(ip != "") print ip 
    }'
}

parse_raw_logs_with_timestamp(){
	fetch_failed_ssh_logs | awk -v ip="" '{
		for(i=1; i<=NF; i++) { if($i == "from") ip=$(i+1)}
		printf "[%s %s %s] - IP Détectée : %s\n", $1, $2, $3, ip 
	}'
}

count_occurences_by_ip(){
	parse_ips_from_logs | sort | uniq -c | sort -rn
}

# Liste les IPs dépassant le seuil (ex: 5)
filter_ips_by_threshold(){
	count_occurences_by_ip | awk -v limit="$BAN_THRESHOLD" '$1 >= limit'
}

# Retourne les IP à bannir après filtrage de la whitelist
identify_malicious_ips(){
	local all_failed_ips=$(filter_ips_by_threshold | awk '{ print $2 }')

	# [[ -f "$WHITELIST_FILE" ]] && cat "$WHITELIST_FILE" || echo "ERROR"

	if [[ ! -s "$WHITELIST_FILE" ]]; then
		echo "$all_failed_ips"  # Si whitelist vide, on laisse tout passer vers le ban
	else
		echo "$all_failed_ips" | grep -Fvf "$WHITELIST_FILE"
	fi

	# grep -Fvf - traites toute la liste d'un coup sans boucle while, ce qui est beaucoup plus rapide
	# 	-F : Traite les entrées comme des chaines fixes (pas de regex)
	#	-v : Inverse la recherche - garde ce qui n'est pas dans la whitelist
	#	-f : Lit les motifs (les IPs à exclure) depuis le fichier spécifié
}