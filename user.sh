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

    log_info "Configuring WSL defaults..."

    grep -q "\[boot\]" /etc/wsl.conf || echo -e "\n[boot]\nsystemd=true" >> /etc/wsl.conf
    grep -q "\[user\]" /etc/wsl.conf || echo -e "\n[user]\ndefault=$username" >> /etc/wsl.conf
}
