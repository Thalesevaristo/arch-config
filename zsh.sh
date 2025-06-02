# Ask user if they want ZSH
ask_install_zsh() {
    read -rp "Do you want to install and configure Zsh? (y/N): " answer
    case "$answer" in
        [Yy]* ) install_and_configure_zsh ;;
        * ) log_info "Skipping Zsh setup." ;;
    esac
}

install_and_configure_zsh() {
    install_packages zsh curl

    read -rp "Do you want to apply customizations for Zsh (Zap + .zshrc)? (y/N): " customize
    if [[ "$customize" =~ ^[Yy]$ ]]; then
        setup_zsh_for_user "$username"
    fi

    change_to_zsh "$username"
}

change_to_zsh() {
    local username=$1
    local ZSH_SHELL="/bin/zsh"

    if ! grep -q "$ZSH_SHELL" /etc/shells; then
        log_error "$ZSH_SHELL is not a valid shell."
        exit 1
    fi

    log_info "Changing default shell for $username to $ZSH_SHELL"
    chsh -s "$ZSH_SHELL" "$username"
}

setup_zsh_for_user() {
    local username=$1
    local user_home="/home/$username"
    local zshrc_path="$user_home/.zshrc"

    log_info "Installing Zap plugin manager..."
    sudo -u "$username" sh -c 'zsh <(curl -s https://raw.githubusercontent.com/zap-zsh/zap/master/install.zsh) --branch release-v1' || {
        log_warn "Failed to install Zap plugin manager, the user can install it manually later"
    }

    chown -R "$username:$username" "$user_home/.zshrc"
    chown -R "$username:$username" "$user_home/.local" 2>/dev/null || true

    if [ -f "$zshrc_path" ]; then
        local timestamp
        timestamp=$(date +"%Y%m%d-%H%M%S")
        local backup_name=".zshrc-$timestamp.bak"
        mv "$zshrc_path" "$user_home/$backup_name"
        echo ".zshrc file backed up as $backup_name"
    fi

    curl -o "$user_home/.zshrc" https://raw.githubusercontent.com/Thalesevaristo/ZSH-Configs/refs/heads/main/.zshrc
    echo "New .zshrc created!"
}
