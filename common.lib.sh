# --- ZONE DE TEST ---
# Simulation de logs si le fichier est vide
generate_test_logs() {
	for i in {1..10}; do
		sudo logger -t sshd "Failed password for invalid user elabs from 45.67.89.101 port 9876 ssh2"
	done
}

# --- LOGIQUE D'EXTRACTION ---
# Première version d'extraction d'un log depuis journalctl
# Format : Mar 17 01:05:33 hostname sshd[21654]: Failed password for root from 192.168.1.100 port 54321 ssh2

extract_data_from_log_V1(){
	journalctl -t sshd --since "today" \
	| grep -i "failed password for" \
	| awk '{ 
		printf "Date: %s %s %s - ", $1, $2, $3; 
		for(i=1; i<=NF; i++) { 
			if($i == "from") print "IP Détectée : " $(i+1) 
		} 
	}'
}

extract_data_from_log_V2(){
	journalctl -t sshd --since "today" \
	| grep -i "failed password for" \
	| awk '{ 
		ip="";
		for(i=1; i<=NF; i++) { 
			if($i == "from") 
				ip=$(i+1);
			}
		printf "Date: %s %s %s - IP Détectée : %s\n", $1, $2, $3, ip  
	}'
}