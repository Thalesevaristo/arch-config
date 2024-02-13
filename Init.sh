#!/usr/bin/env bash
#--------------------------------------------------------------------------

echo -e "
╔========================================================================╗
║                                                                        ║
║  ██████╗░██████╗░░█████╗░██╗██████╗░  ░█████╗░██████╗░░█████╗░██╗░░██╗ ║
║  ██╔══██╗██╔══██╗██╔══██╗██║██╔══██╗  ██╔══██╗██╔══██╗██╔══██╗██║░░██║ ║
║  ██║░░██║██████╔╝██║░░██║██║██║░░██║  ███████║██████╔╝██║░░╚═╝███████║ ║
║  ██║░░██║██╔══██╗██║░░██║██║██║░░██║  ██╔══██║██╔══██╗██║░░██╗██╔══██║ ║
║  ██████╔╝██║░░██║╚█████╔╝██║██████╔╝  ██║░░██║██║░░██║╚█████╔╝██║░░██║ ║
║  ╚═════╝░╚═╝░░╚═╝░╚════╝░╚═╝╚═════╝░  ╚═╝░░╚═╝╚═╝░░╚═╝░╚════╝░╚═╝░░╚═╝ ║
║  Arch Linux WSL From Docker Post Install Setup and Config              ║
╚========================================================================╝
"

echo "----------------------- Initializating Pacman Keys ----------------------"
pacman-key --init
pacman-key --populate
pacman -Sy archlinux-keyring
pacman -Su

echo "----------------------- Instaling Sudo ----------------------------------"
pacman -Syu -y
pacman -S sudo -y

echo "----------------------- Initializating Sudo -----------------------------"
echo "%wheel ALL=(ALL) ALL" > /etc/sudoers.d/wheel

echo "----------------------- Initializating Locale ---------------------------"
locale-gen

echo "----------------------- Instaling Basic Software ------------------------"
pacman -S nano zsh curl git github-cli python rust -y

echo "----------------------- Create a New User -------------------------------"
echo "Username:"
read username
useradd -m -G wheel -s /bin/bash $username -u 1000
passwd $username

echo "----------------------- Setting New User as Default on WSL --------------"
echo -e "[boot]\nsystemd=true\n[user]\ndefault=$username" > /etc/wsl.conf
