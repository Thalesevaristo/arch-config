#!/usr/bin/env bash

# Detect if the script is being run from a pipe and re-execute from a temp file
if [ -t 0 ]; then
  # Running normally (not from a pipe)
  :
else
  # Running from a pipe; save to temp file and execute
  tmp_script=$(mktemp)
  cat > "$tmp_script"
  chmod +x "$tmp_script"
  exec "$tmp_script"
fi

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

# Install required packages
install_packages() {
    log_info "Installing required packages..."
    pacman -Sy --noconfirm || {
        log_error "Package database update failed"
        exit 1
    }
    pacman -Su --noconfirm || {
        log_error "System upgrade failed"
        exit 1
    }

    local packages=(
        sudo nano zsh curl git github-cli python go rust
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

    grep -q "\[boot\]" /etc/wsl.conf || echo -e "\n[boot]\nsystemd=true" >> /etc/wsl.conf
    grep -q "\[user\]" /etc/wsl.conf || echo -e "\n[user]\ndefault=$username" >> /etc/wsl.conf

    # Make Zsh the default shell
    change_to_zsh "$username"
    
    # Setup Zap plugin manager for ZSH
    setup_zsh_for_user "$username"
}

change_to_zsh() {
    local username=$1
    local ZSH_SHELL="/bin/zsh"

    # Verifica se o shell existe
    if ! grep -q "$ZSH_SHELL" /etc/shells; then
        log_error "$ZSH_SHELL is not a valid shell."
        exit 1
    fi

    log_info "Changing default shell for to $ZSH_SHELL"
    chsh -s "$ZSH_SHELL" "$username"
}

# Setup ZSH with Zap plugin manager
setup_zsh_for_user() {
    local username=$1
    local user_home="/home/$username"

    # Install Zap plugin manager for the user
    log_info "Installing Zap plugin manager..."
    sudo -u "$username" sh -c 'zsh <(curl -s https://raw.githubusercontent.com/zap-zsh/zap/master/install.zsh) --branch release-v1' || {
        log_warn "Failed to install Zap plugin manager, the user can install it manually later"
    }
    
    # Set proper ownership
    chown -R "$username:$username" "$user_home/.zshrc"
    chown -R "$username:$username" "$user_home/.local" 2>/dev/null || true
    
    log_info "ZSH with Zap plugin manager has been set up for $username"
    
    log_info "Setting up Zap plugin manager for ZSH..."
    
    # Create initial .zshrc file
    cat > "$user_home/.zshrc" << 'EOF'
# Created by Arch Linux WSL post-installer

# Initialize Zap plugin manager
[ -f "$HOME/.local/share/zap/zap.zsh" ] && source "$HOME/.local/share/zap/zap.zsh"

# History configuration
HISTFILE="$HOME/.zsh_history"
HISTSIZE=10000
SAVEHIST=10000
setopt appendhistory
setopt sharehistory
setopt incappendhistory

# Key bindings
bindkey '^[[A' history-beginning-search-backward
bindkey '^[[B' history-beginning-search-forward

# Aliases
alias ls='ls --color=auto'
alias ll='ls -la'
alias la='ls -a'
alias grep='grep --color=auto'
alias python="python3"

# Path additions
export PATH="$HOME/.local/bin:$PATH"
export PATH=$PATH:/usr/local/go/bin

# Theme
export TYPEWRITTEN_PROMPT_LAYOUT="pure_verbose"
export TYPEWRITTEN_CURSOR="beam"
export TYPEWRITTEN_SYMBOL="$"
export TYPEWRITTEN_RELATIVE_PATH="adaptive"
export TYPEWRITTEN_COLOR_MAPPINGS="primary:#B6D6F2;secondary:#FFF0AA;accent:#BBC4B9;notice:#F2D3B6;info_negative:#FE5A59;info_positive:#a9ffb4;info_neutral_1:#F2C3A6;info_neutral_2:#B6D6F2;info_special:#B3FFDE"
export TYPEWRITTEN_COLORS="host:#FFAAAF;host_user_connector:#BBC4B9;user:#CDFFAA"

# Plugins
plug "zsh-users/zsh-autosuggestions"
plug "zap-zsh/supercharge"
plug "zap-zsh/zap-prompt"
plug "zsh-users/zsh-syntax-highlighting"
plug "reobin/typewritten"

# Load and initialise completion system
autoload -Uz compinit
compinit
EOF
}

# Main function
main() {
    check_root
    show_banner

    # Run setup steps
    install_packages
    setup_sudo
    setup_locale
    create_user

    log_info "Setup completed successfully!"
    log_info "Please restart your WSL instance for changes to take effect."
}

# Run main function
main "$@"
