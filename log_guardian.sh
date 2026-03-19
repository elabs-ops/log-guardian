#!/bin/bash

. ./common.lib.sh

# --- VERIFICATION DES ARGUMENTS ---

do_clean=false
do_test=false

do_get=false
do_extract=false
do_sort=false
do_threshold=false
do_ban=false

do_inspect=false



if [[ "$#" -gt 0 ]]; then
    for arg in "$@"; do
        case "$arg" in 
            --clean)
                do_clean=true
                ;;
            --test)
                do_test=true
                ;;
            --get-failed)
                do_get=true
                ;;
            --extract)
                do_extract=true
                ;;
            --sort)
                do_sort=true
                ;;
            --threshold)
                do_threshold=true
                ;;
            --inspect)
                do_inspect=true
                ;;
            --ban)
                do_ban=true
                ;;
            *)
                echo "Argument inconnu : $arg"
                ;;
        esac
    done
fi


# Exécution dans l'ordre souhaité
if $do_clean; then
    echo "Nettoyage du journal de log ssh..."
    reset_sshd_logs
fi

if $do_test; then
    echo "Generation de logs..."
    generate_test_logs
fi

if $do_get; then
    get_failed_lines
fi

if $do_inspect; then
    echo "Inspect Failed Attempt"
    inspect_failed_attempts
fi

if $do_extract; then
    extract_ips
fi

if $do_sort; then
    sort_ips
fi

if $do_threshold; then
    filter_by_threshold
fi

if $do_ban; then
    add_ip_to_ban_list
fi











