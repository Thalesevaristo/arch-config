#!/usr/bin/env bash

# Set strict error handling
set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source utility functions
source "$SCRIPT_DIR/utils.sh"

# Source the package list
if [ ! -f "packages.conf" ]; then
    log_error "Error: packages.conf not found!"
    exit 1
fi
source "$SCRIPT_DIR/packages.conf"

# Main function
main() {
    clear
    
    # Configura sudo e locale
    setup_sudo
    setup_locale
    
    check_root
    show_banner

    # Atualiza o sistema
    log_info "Updating system..."
    sudo pacman -Syu --noconfirm

    # Instala pacotes básicos
    log_info "Installing required packages..."
    install_packages "${PACKAGES[@]}"

    # Criação do usuário
    create_user

    # Instalação e customização opcional do Zsh
    ask_install_zsh

    log_info "Setup completed successfully!"
    log_info "Please restart your WSL instance for changes to take effect."
}

main "$@"
