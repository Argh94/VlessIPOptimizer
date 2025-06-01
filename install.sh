#!/bin/bash

# Colors for output
red='\033[0;31m'
green='\033[0;32m'
cyan='\033[0;36m'
rest='\033[0m'

# Display installation header
echo -e "${cyan}===========================================${rest}"
echo -e "${cyan}|        Installing VlessIPOptimizer        |${rest}"
echo -e "${cyan}| GitHub: ${green}https://github.com/Argh94${rest} |${rest}"
echo -e "${cyan}===========================================${rest}"

# Update and install Termux packages
echo -e "${cyan}Updating and installing required Termux packages...${rest}"
pkg update -y && pkg upgrade -y
pkg install bash curl git -y
if [[ $? -ne 0 ]]; then
    echo -e "${red}Error: Failed to install or update Termux packages.${rest}"
    exit 1
fi

# Download the main script
echo -e "${cyan}Downloading VlessIPOptimizer script...${rest}"
curl -L -o vless_ip_optimizer.sh -# --retry 2 https://raw.githubusercontent.com/Argh94/VlessIPOptimizer/main/vless_ip_optimizer.sh
if [[ $? -ne 0 ]]; then
    echo -e "${red}Error: Failed to download VlessIPOptimizer script.${rest}"
    exit 1
fi

# Make the script executable
chmod +x vless_ip_optimizer.sh

# Run the script
echo -e "${green}Starting VlessIPOptimizer...${rest}"
./vless_ip_optimizer.sh
