#!/usr/bin/env bash

# Set strict error handling
set -euo pipefail
IFS=$'\n\t'

# Source utility functions
source utils.sh
source user.sh
source zsh.sh

# Source the package list
if [ ! -f "packages.conf" ]; then
    log_error "Error: packages.conf not found!"
    exit 1
fi
source packages.conf

# Main function
main() {
    clear
    check_root
    show_banner

    # Atualiza o sistema
    log_info "Updating system..."
    sudo pacman -Syu --noconfirm

    # Instala pacotes básicos
    log_info "Installing required packages..."
    install_packages "${PACKAGES[@]}"

    # Configura sudo e locale
    setup_sudo
    setup_locale

    # Criação do usuário
    create_user

    # Instalação e customização opcional do Zsh
    if prompt_yes_no "Deseja instalar o Zsh?"; then
        install_packages zsh
        local username
        username=$(get_default_user)

        if prompt_yes_no "Deseja aplicar customizações no Zsh (Zap e .zshrc)?"; then
            change_to_zsh "$username"
            setup_zsh_for_user "$username"
        fi
    fi

    log_info "Setup completed successfully!"
    log_info "Please restart your WSL instance for changes to take effect."
}

main "$@"
