#!/bin/bash
set -e

PROJECT_ROOT=$(dirname "$(readlink -f "$0")")
cd "$PROJECT_ROOT"

. "${PROJECT_ROOT}/lib/utils.lib.sh"

display_info "Installation de l'outil LogGuardian"

# Interdire root
if [[ "$EUID" -eq 0 ]]; then
    display_error "Ne lancez pas l'installation en root. Exécutez : ./install.sh"
    exit 1
fi

# 1. Créer l'arborescence (via ta fonction dans utils.lib.sh)
ensure_directories_exist

# 2. Rendre le script principal exécutable
chmod 700 "${PROJECT_ROOT}/bin/main.sh" 

# 3. Gestion du lien symbolique
bin_path="${HOME}/.local/bin"
bin_name="logguardian"
full_bin_path="${bin_path}/${bin_name}"

mkdir -p "$bin_path"

# ln -sf écrase le lien s'il existe déjà, c'est plus propre
ln -sf "${PROJECT_ROOT}/bin/main.sh" "$full_bin_path"

display_success "Lien créé : $full_bin_path -> bin/main.sh"

# 4. Vérification et mise à jour du PATH
if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    display_info "Ajoutez ~/.local/bin à votre PATH :"
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> ${HOME}/.bashrc
    source ${HOME}/.bashrc
    display_success "PATH mis à jour."
fi

# 5. Instructions sudoers pour l'automatisation
echo -e "\n${YELLOW}--- CONFIGURATION SUDOERS REQUISE ---${RESET}"
echo "Pour permettre le bannissement automatique sans mot de passe,"
echo "ajoutez la ligne suivante via 'sudo visudo' :"
echo -e "\n${GREEN}$USER ALL=(root) NOPASSWD: $full_bin_path --apply-bans${RESET}\n"

display_success "Installation terminée avec succès !"


# Vérifier si le lien symb existe -L
#if [[ -L "$full_bin_path" ]]; then
#	rm "$full_bin_path"
#fiport