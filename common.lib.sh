# Empêche l'exécution automatique si le fichier est sourcé
(return 0 2>/dev/null) || exit 0


# --- ZONE DE TEST ---

# Nettoyer le journal de log sshd
reset_sshd_logs(){
	echo "Rotation du journal"
	# ferme le fichier courant et ouvre un nouveau
	sudo journalctl --rotate 

	echo "Suppression des anciens logs (garde seulement 1 seconde..."
	# Supprime tous les journaux plus vieux que 1 seconde
	sudo journalctl --vacuum-time=1s

	echo "Nettoyage terminé"
}

# Simulation de logs si le fichier est vide
generate_test_logs(){
	IPS=("185.203.44.12" "102.54.11.90" "203.0.113.77")
	USERS=("admin" "test" "root" "ubuntu" "elabs")
	COUNT=30

	for ((i=1; i<=COUNT; i++)); do

		# $RANDOM génère un nombre aléatoire 
		# ${#IPS[@]} = nombre d’IP dans le tableau
		# % = modulo → ramène l’index dans la plage 0..(n-1) - ici 0..2
		IP=${IPS[$RANDOM % ${#IPS[@]}]}

		USER=${USERS[$RANDOM % ${#USERS[@]}]}

		# Génère un port aléatoire entre 40000 et 59999
    	# $RANDOM % 20000 → 0 à 19999
    	# + 40000 → décalage vers 40000..59999
    	# Cela simule des ports éphémères réalistes.
		PORT=$((RANDOM % 20000 + 40000))

		logger -t sshd "Failed password for invalid user $USER from $IP port $PORT ssh2"

		# Pause de 0,1 seconde pour éviter que les logs soient générés tous à la même milliseconde.
    	sleep 0.1
	done
}

# --- LOGIQUE D'EXTRACTION ---
# Première version d'extraction d'un log depuis journalctl
# Format : Mar 17 01:05:33 hostname sshd[21654]: Failed password for root from 192.168.1.100 port 54321 ssh2


get_failed_lines(){
	journalctl -t sshd --since today | grep -i "failed password"
}

inspect_failed_attempts(){
	get_failed_lines \
	| awk '{ 
		ip="";
		for(i=1; i<=NF; i++) { 
			if($i == "from") 
				ip=$(i+1);
			}
		printf "Date: %s %s %s - IP Détectée : %s\n", $1, $2, $3, ip  
	}'
}

extract_ips(){
	get_failed_lines | awk '{ 
		ip="";
		for(i=1; i<=NF; i++) { 
			if($i == "from") 
				ip=$(i+1);
			}
		printf "%s\n", ip  
	}'
}

sort_ips(){
	extract_ips | sort | uniq -c | sort -rn
}

filter_by_threshold(){
	sort_ips | awk '{ if($1 >= 10) print $2 }'
}

export_ips(){
	filter_by_threshold > fail2ban.txt
}

ban_ips(){
	echo "TO DO: BAN IP"
}
