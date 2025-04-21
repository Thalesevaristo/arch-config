#!/usr/bin/env bash

curl -o init.sh https://raw.githubusercontent.com/Thalesevaristo/Arch_config/refs/heads/main/Init.sh
chmod +x init.sh
exec init.sh
rm init.sh
