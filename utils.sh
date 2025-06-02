# utils.sh

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
    ... (mesmo conteúdo do banner) ...
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
