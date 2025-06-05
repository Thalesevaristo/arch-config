# -----------------------
# Logging
# -----------------------

# Color definitions
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m' # No Color

# Logging functions
log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# -----------------------
# Package and system
# -----------------------

# Display banner
show_banner() {
    cat << "EOF"
╔════════════════════════════════════════════════════════════╗
║                                                            ║
║    ██████████   █████   █████ ████████████    ████████     ║
║   ███░░░░░░███ ░░███   ░░███ ░█░░░████░░░█  ███░░░░░░███   ║
║  ░███     ░███  ░███    ░███ ░   ░████  ░  ███      ░░███  ║
║  ░████████████  ░███    ░███     ░████    ░███       ░███  ║
║  ░███░░░░░░███  ░███    ░███     ░████    ░███       ░███  ║
║  ░███     ░███  ░███    ░███     ░████    ░░███      ███   ║
║  █████    █████ ░░█████████      ██████    ░░░████████░    ║
║  ░░░░░    ░░░░░   ░░░░░░░░░      ░░░░░░       ░░░░░░░░     ║
║                                                            ║
║  The Arch Linux Post-Installer for WSL                     ║
║  Initial Setup and Config                                  ║
╚════════════════════════════════════════════════════════════╝
EOF
}

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run as root"
        exit 1
    fi
}

# Verifica se um pacote está instalado
is_installed() {
  pacman -Qi "$1" &> /dev/null
}

# Verifica se um grupo está instalado
is_group_installed() {
  pacman -Qg "$1" &> /dev/null
}

# Instala pacotes se não estiverem instalados
install_packages() {
  local packages=("$@")
  local to_install=()

  for pkg in "${packages[@]}"; do
    if ! is_installed "$pkg" && ! is_group_installed "$pkg"; then
      to_install+=("$pkg")
    fi
  done

  if [ ${#to_install[@]} -ne 0 ]; then
    log_info "Installing: ${to_install[*]}"
    pacman -S --noconfirm "${to_install[@]}" || {
        log_error "Failed to install ${to_install[@]}"
        exit 1
    }
  fi
}

# -----------------------
# Sudo
# -----------------------
setup_sudo() {
    log_info "Installing sudo..."
    install_packages "sudo"
    log_info "Configuring sudo..."
    echo "%wheel ALL=(ALL) ALL" > /etc/sudoers.d/wheel
    chmod 440 /etc/sudoers.d/wheel
}

# -----------------------
# Setup locale
# -----------------------
setup_locale() {
    log_info "Setting up locale..."
    locale-gen || {
        log_warn "Locale generation encountered issues"
    }
}


# -----------------------
# User
# -----------------------

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

    while true; do
        if passwd "$username"; then
            break
        else
            log_warn "Password setting failed, please try again"
        fi
    done

    GLOBAL_USERNAME="$username"
    log_info "Configuring WSL defaults..."

    grep -q "\[boot\]" /etc/wsl.conf || echo -e "\n[boot]\nsystemd=true" >> /etc/wsl.conf
    grep -q "\[user\]" /etc/wsl.conf || echo -e "\n[user]\ndefault=$username" >> /etc/wsl.conf
}

# -----------------------
# Zsh
# -----------------------

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
        setup_zsh_for_user "$GLOBAL_USERNAME"
    fi

    change_to_zsh "$GLOBAL_USERNAME"
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
