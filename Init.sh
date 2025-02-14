#!/usr/bin/env bash

# Set strict error handling
set -euo pipefail
IFS=$'\n\t'

# Color definitions
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m' # No Color

# Logging functions
log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Display banner
show_banner() {
    cat << "EOF"
╔=========================================================╗
║                                                         ║
║    █████████   █████  █████ ███████████    ███████      ║
║   ███░░░░░███ ░░███  ░░███ ░█░░░███░░░█  ███░░░░░███    ║
║  ░███    ░███  ░███   ░███ ░   ░███  ░  ███     ░░███   ║
║  ░███████████  ░███   ░███     ░███    ░███      ░███   ║
║  ░███░░░░░███  ░███   ░███     ░███    ░███      ░███   ║
║  ░███    ░███  ░███   ░███     ░███    ░░███     ███    ║
║  █████   █████ ░░████████      █████    ░░░███████░     ║
║  ░░░░░   ░░░░░   ░░░░░░░░      ░░░░░       ░░░░░░░      ║
║                                                         ║
║  The Arch Linux Post-Installer for WSL                  ║
║  Initial Setup and Config                               ║
╚=========================================================╝
EOF
}

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run as root"
        exit 1
    fi
}

# Initialize pacman keys
init_pacman() {
    log_info "Initializing pacman keys..."
    pacman-key --init
    pacman-key --populate
    pacman -Sy archlinux-keyring --noconfirm || {
        log_error "Failed to initialize pacman keys"
        exit 1
    }
    pacman -Su --noconfirm
}

# Install required packages
install_packages() {
    log_info "Installing required packages..."
    pacman -Syu --noconfirm || {
        log_error "System update failed"
        exit 1
    }

    local packages=(
        sudo
        nano
        zsh
        curl
        git
        github-cli
        python
	go
        rust
    )

    pacman -S "${packages[@]}" --noconfirm || {
        log_error "Failed to install packages"
        exit 1
    }
}

# Configure sudo
setup_sudo() {
    log_info "Configuring sudo..."
    echo "%wheel ALL=(ALL) ALL" > /etc/sudoers.d/wheel
    chmod 440 /etc/sudoers.d/wheel
}

# Setup locale
setup_locale() {
    log_info "Setting up locale..."
    locale-gen || {
        log_warn "Locale generation encountered issues"
    }
}

# Create new user
create_user() {
    local username
    while true; do
        read -rp "Enter username (letters and numbers only): " username
        if [[ "$username" =~ ^[A-Za-z][a-z0-9-]*$ ]]; then
    			break
        else
            log_error "Invalid username format. Please use lowercase letters and numbers only."
        fi
    done

    log_info "Creating user: $username"
    useradd -m -G wheel -s /bin/bash "$username" -u 1000 || {
        log_error "Failed to create user"
        exit 1
    }

    # Set password
    while true; do
        if passwd "$username"; then
            break
        else
            log_warn "Password setting failed, please try again"
        fi
    done

    # Configure WSL default user
    log_info "Configuring WSL defaults..."
    cat > /etc/wsl.conf << EOF
[boot]
systemd=true

[user]
default=$username
EOF
}

# Main function
main() {
    check_root
    show_banner

    # Run setup steps
    init_pacman
    install_packages
    setup_sudo
    setup_locale
    create_user

    log_info "Setup completed successfully!"
    log_info "Please restart your WSL instance for changes to take effect."
}

# Run main function
main "$@"
