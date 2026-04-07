#!/bin/bash

# --- CONSTANTES GLOBALES ---

# Couleur pour les messages console (echo)
#readonly RED="\e[31m"
#readonly GREEN="\e[32m"
#readonly YELLOW="\e[33m"
#readonly RESET="\e[0m"

#  awk ne comprend que \033 ou \x1b pour ESC, pas \e

readonly RED="\033[31m"
readonly GREEN="\033[32m"
readonly YELLOW="\033[33m"
readonly RESET="\033[0m"


# On définit le chemin du fichier config
readonly CONFIG_PATH="config/guardian.conf"

# On charge le fichier s'il existe
if [[ -f "$CONFIG_PATH" ]]; then
    source "$CONFIG_PATH"
fi

# Valeurs par défaut (si non définies dans le .conf)
readonly BAN_THRESHOLD="${BAN_THRESHOLD:-5}"
readonly APP_VAR_DIR="${VAR_DIR:-var}"
readonly APP_LOG_DIR="${LOG_DIR:-log}"
readonly APP_CONF_DIR="${CONF_DIR:-config}"


readonly APP_VAR_REPORTS_DIR="var/reports"

# Chemins complets
readonly BANNED_IPS_DB="$APP_VAR_DIR/${BANNED_DB:-banned_ips.db}"
readonly WHITELIST_FILE="$APP_CONF_DIR/${WHITELIST:-whitelist.conf}"
readonly FIREWALL_LOG="$APP_LOG_DIR/${REPORT_LOG:-firewall_activity.log}"

ensure_directories_exist() {
    # Création des dossiers uniquement si NON-root
    if [[ "$EUID" -ne 0 ]]; then
        mkdir -p "$APP_VAR_DIR" "$APP_LOG_DIR" "$APP_CONF_DIR" "$APP_VAR_REPORTS_DIR"
        [[ -f "$BANNED_IPS_DB" ]] || touch "$BANNED_IPS_DB"
        [[ -f "$FIREWALL_LOG" ]] || touch "$FIREWALL_LOG"

        # Fichier de config : peut être dans le repo
        [[ -f "$WHITELIST_FILE" ]] || touch "$WHITELIST_FILE"
    fi
}


ensure_root_permission() {
    # EUID = 1000 (USER), EUID = 0 (ROOT)
    [[ "$EUID" -ne 0 ]] && { 
        display_error "Permissions requises pour effectuer cette action"
        exit 1
    }
}

ensure_not_root_permission() {
    # EUID = 1000 (USER), EUID = 0 (ROOT)
    [[ "$EUID" -eq 0 ]] && { 
        display_error "Evitez de créer des fichiers en utilisant sudo ou en étant connecté en root"
        exit 1
    }
}

ensure_local_ips_whitelisted() {
    local local_ip=$(hostname -I | awk '{ print $1 }')
    local loopback="127.0.0.1"

    require_runtime_file "$WHITELIST_FILE"

    for ip in "$local_ip" "$loop"; do
        if [[ -n "$ip" ]] && ! grep -q "$ip" "$WHITELIST_FILE"; then
            echo "$ip" >> "$WHITELIST_FILE"
            display_info "Protection : $ip ajouté à la whitelist (auto)."
        fi
    done

}

require_runtime_file(){
    echo "DANS REQUIRE"
    local file="$1"
    if [[ ! -f "$file" ]]; then
        display_error "Fichier runtime manquant : $file"
        display_error "Veuillez exécuter : logguardian --repair"
        exit 1
    fi
}


display_info() { echo -e "${YELLOW}[INFO]${RESET} $1"; }
display_success() { echo -e "${GREEN}[OK]${RESET} $1"; }
display_error() { echo -e "${RED}[ERROR]${RESET} $1"; >&2; }

# Fonction de log interne pour le script
log_message() {
    echo -e "$(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_event() {
    echo -e "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$FIREWALL_LOG"
}