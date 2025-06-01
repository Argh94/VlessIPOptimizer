#!/bin/bash

# Colors for output
red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
blue='\033[0;34m'
purple='\033[0;35m'
cyan='\033[0;36m'
white='\033[0;37m'
rest='\033[0m'

# Clean up temporary files on exit
trap 'rm -f warpendpoint ip.txt vless_ip_optimizer.sh >/dev/null 2>&1' EXIT

# Install and update Termux packages
echo -e "${cyan}Updating and installing required Termux packages...${rest}"
pkg update -y && pkg upgrade -y
pkg install bash curl git -y
if [[ $? -ne 0 ]]; then
    echo -e "${red}Error: Failed to install or update Termux packages.${rest}"
    exit 1
fi

# Clear the console and display header
clear
echo -e "${cyan}===========================================${rest}"
echo -e "${cyan}|        Installing VlessIPOptimizer        |${rest}"
echo -e "${cyan}| GitHub: ${green}https://github.com/Argh94${rest} |${rest}"
echo -e "${cyan}===========================================${rest}"

# Determine the system architecture
case "$(uname -m)" in
    x86_64 | x64 | amd64 )
        cpu=amd64
    ;;
    i386 | i686 )
        cpu=386
    ;;
    armv8 | armv8l | arm64 | aarch64 )
        cpu=arm64
    ;;
    armv7l )
        cpu=arm
    ;;
    * )
        echo -e "${red}The current architecture is $(uname -m), not supported${rest}"
        exit 1
    ;;
esac

# Function to download warpendpoint program
cfwarpIP() {
    if [[ ! -f "$PREFIX/bin/warpendpoint" ]]; then
        echo -e "${cyan}Downloading warpendpoint program${rest}"
        if [[ -n $cpu ]]; then
            curl -L -o warpendpoint -# --retry 2 https://raw.githubusercontent.com/Ptechgithub/warp/main/endip/$cpu
            if [[ $? -ne 0 ]]; then
                echo -e "${red}Error: Failed to download warpendpoint.${rest}"
                exit 1
            fi
            cp warpendpoint $PREFIX/bin
            chmod +x $PREFIX/bin/warpendpoint
        fi
    fi
}

# Function to generate random IPv4 addresses
endipv4() {
    n=0
    iplist=100
    prefixes=("162.159.192" "162.159.193" "162.159.195" "188.114.96" "188.114.97" "188.114.98" "188.114.99")
    while [ $(echo ${temp[@]} | sed -e 's/ /\n/g' | sort -u | wc -l) -lt $iplist ]
    do
        prefix=${prefixes[$((RANDOM % ${#prefixes[@]}))]}
        temp[$n]=$(echo $prefix.$((RANDOM%256)))
        ((n++))
    done
}

# Function to process and display the best IP results
endipresult() {
    echo ${temp[@]} | sed -e 's/ /\n/g' | sort -u > ip.txt
    ulimit -n 102400
    chmod +x warpendpoint >/dev/null 2>&1
    if command -v warpendpoint &>/dev/null; then
        warpendpoint
    else
        ./warpendpoint
    fi

    if [[ ! -f result.csv || ! -s result.csv ]]; then
        echo -e "${red}Error: result.csv not found or empty.${rest}"
        exit 1
    fi

    clear
    cat result.csv | awk -F, '$3!="timeout ms" {print} ' | sort -t, -nk2 -nk3 | uniq | head -11 | awk -F, '{print "Endpoint "$1" Packet Loss Rate "$2" Average Delay "$3}'
    Endip_v4=$(cat result.csv | grep -oE "[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+:[0-9]+" | head -n 1)
    delay=$(cat result.csv | grep -oE "[0-9]+ ms|timeout" | head -n 1)
    echo ""
    echo -e "${green}Results Saved in result.csv${rest}"
    echo ""
    if [ "$Endip_v4" ]; then
        echo -e "${purple}************************************${rest}"
        echo -e "${purple}*           ${yellow}Best IPv4:Port${purple}         *${rest}"
        echo -e "${purple}*                                  *${rest}"
        echo -e "${purple}*          ${cyan}$Endip_v4${purple}     *${rest}"
        echo -e "${purple}*           ${cyan}Delay: ${green}[$delay]        ${purple}*${rest}"
        echo -e "${purple}************************************${rest}"
    else
        echo -e "${red} No valid IP addresses found.${rest}"
    fi
}

# Function to process the VLESS configuration
process_vless_config() {
    local vless_url="$1"
    local endip_v4="$2"
    local host=$(echo "$vless_url" | grep -oP '(?<=host=)[^&]*')
    local port=$(echo "$vless_url" | grep -oP '(?<=@)[^:]*:\K[^?]*')

    if [[ -z "$host" || -z "$port" ]]; then
        echo -e "${red}Error: Host and Port must be present in the VLESS config.${rest}"
        exit 1
    fi

    local address=$(echo "$endip_v4" | cut -d: -f1)
    local new_vless_url=$(echo "$vless_url" | sed -E "s/@[^:]*:[^?]*\?/@$address:$port?/")

    new_vless_url=$(echo "$new_vless_url" | sed -E "s/#.*$/#Powerful By @PowerSigma/")

    echo "$new_vless_url"
}

# Request VLESS config URL from the user
echo -en "${cyan}Enter your VLESS config URL: ${rest}"
read -r vless_url

# Validate the VLESS config URL
if [[ ! "$vless_url" =~ vless:// ]]; then
    echo -e "${red}Invalid VLESS config URL.${rest}"
    exit 1
fi

# Automatically process the IPv4 selection
cfwarpIP
endipv4
endipresult

# Process VLESS configuration with new IP and port
new_vless_url=$(process_vless_config "$vless_url" "$Endip_v4")
echo -e "${green}New VLESS config:${rest} $new_vless_url"
