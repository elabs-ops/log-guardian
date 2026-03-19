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
	IPS=("185.203.44.12" "102.54.11.90" "203.0.113.77" "192.168.1.6")
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

# --- LOGIQUE D'EXTRACTION  ET SECURITÉ ---
# Format : Mar 17 01:05:33 hostname sshd[21654]: Failed password for root from 192.168.1.100 port 54321 ssh2

# Récupère les lignes de logs SSH concernant les échecs de connexion depuis le début de la journée (--since today)
get_failed_lines(){
	journalctl -t sshd --since today | grep -i "failed password"
}

# Affiche un résumé lisible (Date + IP) des tentatives infructueuses.
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

# Extrait uniquement les adresses IP des tentatives infructueuses.
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

# Compte les occurrences de chaque IP et les trie de la plus active à la moins active.
#	1 - sort : trie les ips
#	2 - uniq -c : compte les occurences et les affiches sur 1 lignes
#	3 - sort -rn : trie en ordre décroissant(reverse) par rapport au nombre (numeric)
sort_ips(){
	extract_ips | sort | uniq -c | sort -rn
}

# Filtre les adresses IP ayant dépassé un seuil critique (ici >= 5 tentatives).
filter_by_threshold(){
	sort_ips | awk '{ if($1 >= 5) print $2 }'
}

# Compare les IPs suspectes avec la liste blanche et ne garde que celles à bannir.
apply_whitelisted(){
	local WHITELIST="whitelist.conf"

	if [[ ! -f "$WHITELIST" ]]; then
		echo "Erreur : fichier introuvalble"
		return 1
	fi

	# grep -Fvf - traites toute la liste d'un coup sans boucle while, ce qui est beaucoup plus rapide
	# 	-F : Traite les entrées comme des chaines fixes (pas de regex)
	#	-v : Inverse la recherche - garde ce qui n'est pas dans la whitelist
	#	-f : Lit les motifs (les IPs à exclure) depuis le fichier spécifié
	filter_by_threshold | grep -Fvf "$WHITELIST"   
}

# Met à jour le fichier de bannissement en fusionnant les anciennes IPs et les nouvelles, sans doublons.
add_ip_to_ban_list(){
    local FILE="fail2ban.txt"
    touch "$FILE"

    (
        cat "$FILE"
        apply_whitelisted
    ) | sort -u > "${FILE}.tmp" && mv "${FILE}.tmp" "$FILE"
}





# Historirque fonctions mal implementée pour garder une trace des erreurs commises

# Version avec while read - À éviter car ouvre le fichier à chaque appel de grep ce qui peut etre problématique sur une longue liste 
apply_whitelisted_v1(){
	local WHITELIST="whitelist.conf"

	if [[ ! -f "$WHITELIST" ]]; then
		echo "Erreur : fichier introuvalble"
		return 1
	fi

	filter_by_threshold \
	| while read -r SUSPICIOUS_IP; do
		echo "IP : $SUSPICIOUS_IP"
		if grep -Fq "$SUSPICIOUS_IP" $WHITELIST; then
			echo "L'ip $SUSPICIOUS_IP est en whiltelist, on ignore"
		else
			echo "$SUSPICIOUS_IP" >> fail2ban.txt
		fi
	  done 
}


# Mauvais exemple : > FILE vide le contenu original du fichier avant même de le lire
add_ip_to_ban_list_v1(){
	local FILE="fail2ban.txt"
	touch $FILE

	{
		cat $FILE 
		apply_whitelisted_v2
	} | sort -u > $FILE 
}


