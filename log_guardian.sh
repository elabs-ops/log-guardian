#!/bin/bash

. ./common.lib.sh

# --- VERIFICATION DES ARGUMENTS ---

do_clean=false
do_mock=false

do_filter=false
do_extract_ip=false
do_stats=false
do_threshold=false
do_build_banlist=false
do_apply_firewall=false

do_inspect=false



if [[ "$#" -gt 0 ]]; then
    for arg in "$@"; do
        case "$arg" in 
            --clean)
                do_clean=true
                ;;
            --mock)
                do_mock=true
                ;;
            --filter-failed)
                do_filter=true
                ;;
            --extract-ip)
                do_extract_ip=true
                ;;
            --stats)
                do_stats=true
                ;;
            --threshold)
                do_threshold=true
                ;;
            --inspect)
                do_inspect=true
                ;;
            --build-banlist)
                do_build_banlist=true
                ;;
            --apply-firewall)
                do_apply_firewall=true
                ;;
            --list-ban)
                list_ban
                ;;
            --clear-ban)
                clear_ban
                ;;
            --report)
                generate_report
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

if $do_mock; then
    echo "Generation de logs..."
    generate_test_logs
fi

if $do_filter; then
    filter_failed_lines
fi

if $do_inspect; then
    echo "Inspect Failed Attempt"
    inspect_failed_attempts
fi

if $do_extract_ip; then
    extract_ips
fi

if $do_stats; then
    stats_ips
fi

if $do_threshold; then
    filter_by_threshold
fi

if $do_build_banlist; then
    echo "Sauvegarde des ip menaçante dans ./fail2ban.txt..."
    add_ip_to_ban_list
fi

if $do_apply_firewall; then
    ban_ips
fi











