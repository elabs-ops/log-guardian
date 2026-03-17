#!/bin/bash

. ./common.lib.sh

# --- VERIFICATION DES ARGUMENTS ---
# On vérifie la présence d'argument
if [[ "$#" -gt 0 ]]; then
    for arg in "$@"; do
        # Si --test présent on lance la generation de tests
        if [[ "$arg" == "--test" ]]; then
            generate_test_logs
        fi
    done
fi

echo "V1..."
extract_data_from_log_V1
echo "V2..."
extract_data_from_log_V2








