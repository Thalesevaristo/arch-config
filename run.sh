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
    
    # Setup sudo and locale
    setup_sudo
    setup_locale
    
    check_root
    show_banner

    # Update the system
    log_info "Updating system..."
    sudo pacman -Syu --noconfirm

    # Install basic packages
    log_info "Installing required packages..."
    install_packages "${PACKAGES[@]}"

    # Create user
    create_user

    # Install UV
    install_uv

    # Instalação e customização opcional do Zsh
    ask_install_zsh

    log_info "Setup completed successfully!"
    log_info "Please restart your WSL instance for changes to take effect."
}

main "$@"
