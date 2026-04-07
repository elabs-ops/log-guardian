#!/bin/bash

# --- MOCK SSH DATA ---

# Nettoyer le journal de log sshd
flush_system_logs(){
 	# ferme le fichier courant et ouvre un nouveau   
    journalctl --rotate
    # Supprime tous les journaux plus vieux que 1 seconde
    journalctl --vacuum-time=1s
}

# Simulation de logs si le fichier est vide
mock_ssh_attacks(){
	local ips=("185.203.44.12" "102.54.11.90" "203.0.113.77" "192.168.1.6")
	local users=("admin" "test" "root" "ubuntu" "elabs")
	local count=30

	log_message "${GREEN}Génération de ${count} faux logs SSH...${RESET}"

	for ((i=1; i<=count; i++)); do
		local ip=${ips[$RANDOM % ${#ips[@]}]}
		local user=${users[$RANDOM % ${#users[@]}]}
		local port=$((RANDOM % 20000 + 40000))

		logger -t sshd "Failed password for invalid user $user from $ip port $port ssh2"
		# Pause de 0,1 seconde pour éviter que les logs soient générés tous à la même milliseconde.
    	sleep 0.1
	done
}

