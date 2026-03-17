#!/bin/bash

# --- ZONE DE TEST ---
# Simulation de logs si le fichier est vide
# sudo logger -t sshd "Failed password for root from 192.168.1.100 port 54321 ssh2"

# --- LOGIQUE D'EXTRACTION ---
# On commence par tester l'extraction sur les 5 dernières tentatives
journalctl -t sshd -n 10 | grep "Failed password for" | awk '{
    printf "Date : %s %s %s - ", $1, $2, $3;
    for(i=1; i<=NF; i++) {
        if($i == "from") print "IP Détectée : " $(i+1)
    }
}'


