#!/usr/bin/env bash

set -e

# Setting up colors for echo commands
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
RED='\033[0;31m'
LIGHT_BLUE='\033[1;34m'
NC='\033[0m' # No Color

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Please run this script with sudo.${NC}"
    exit 1
fi

# Check Ubuntu 22.04
if [ "$(lsb_release -is)" != "Ubuntu" ] || [ "$(lsb_release -rs)" != "22.04" ]; then
    echo -e "${RED}This script is only compatible with Ubuntu 22.04.${NC}"
    exit 1
fi

# Retrieve server IP
server_ip=$(hostname -I | awk '{print $1}')

# Prompt user for site name
read -p "Enter the website name: " site_name

# Set default passwords
sql_password="123123"
admin_password="123123"

# Installing required packages
echo -e "${YELLOW}Installing required packages...${NC}"
sleep 2

sudo apt update
sudo apt upgrade -y
sudo apt install software-properties-common git curl python3-dev python3-setuptools python3-venv python3-pip python3-distutils redis-server mariadb-server mariadb-client build-essential zlib1g-dev libncurses5-dev libgdbm-dev libnss3-dev libssl-dev libreadline-dev libffi-dev libsqlite3-dev wget libbz2-dev fontconfig xvfb libfontconfig wkhtmltopdf -y

echo -e "${GREEN}Packages installed.${NC}"
sleep 2

# Install Python 3.10 if not already installed or version is less than 3.10
py_version=$(python3 --version 2>&1 | awk '{print $2}')
py_major=$(echo "$py_version" | cut -d '.' -f 1)
py_minor=$(echo "$py_version" | cut -d '.' -f 2)

if [ -z "$py_version" ] || [ "$py_major" -lt 3 ] || [ "$py_major" -eq 3 -a "$py_minor" -lt 10 ]; then
    echo -e "${LIGHT_BLUE}Installing Python 3.10+...${NC}"
    sleep 2

    sudo apt -qq install python3.10 python3.10-dev python3.10-venv -y
    sudo update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.10 1
    sudo update-alternatives --set python3 /usr/bin/python3.10
    sudo apt install python3-pip -y
    sudo pip3 install --user --upgrade pip
    echo -e "${GREEN}Python3.10 installation successful!${NC}"
    sleep 2
fi

# Install NVM, Node, npm, and yarn
echo -e "${YELLOW}Installing NVM, Node, npm, and yarn...${NC}"
sleep 2
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
source ~/.bashrc

nvm install --lts

sudo apt-get -qq install npm -y
sudo npm install -g yarn

echo -e "${GREEN}NVM, Node, npm, and yarn installed.${NC}"
sleep 2

# Install Frappe Bench
echo -e "${YELLOW}Installing Frappe Bench...${NC}"
sleep 2
sudo pip3 install frappe-bench

# Initialize bench in frappe-bench folder
echo -e "${YELLOW}Initializing bench in frappe-bench folder...${NC}"
sudo -u frappe bench init frappe-bench --verbose --python $(which python3)

# Go to frappe-bench directory
cd frappe-bench

# Create new site with ERPNext, HRMS, and Chat
echo -e "${YELLOW}Creating a new site with ERPNext, HRMS, and Chat...${NC}"
sudo -u frappe bench --site $site_name --install-app erpnext --install-app hrms --install-app chat
echo -e "${GREEN}Site created.${NC}"

# Set MySQL root password
sudo mysqladmin -u root password $sql_password

# Set up in production mode
echo -e "${YELLOW}Setting up in production mode...${NC}"
sleep 2
sudo -u frappe bench setup production $USER

# Set site administrator password
sudo -u frappe bench --site $site_name set-admin-password $admin_password

# Restart services
sudo service supervisor restart
sudo service nginx restart

# Update supervisorctl in PATH
export PATH=$PATH:/usr/bin
echo 'export PATH=$PATH:/usr/bin' >> ~/.bashrc

echo -e "${GREEN}Setup completed successfully.${NC}"
sleep 2

# Display information
echo -e "${GREEN}-----------------------------------------------------------------------------------------------"
echo -e "Congratulations! You have successfully installed ERPNext, HRMS, and Chat on your Ubuntu 22.04 system."
echo -e "You can access your ERPNext instance by visiting https://$site_name"
echo -e "Login with the following credentials:"
echo -e "Administrator: Administrator"
echo -e "Password: $admin_password"
echo -e "Make sure to change the default passwords after the first login."
echo -e "For more information, visit https://docs.erpnext.com for Documentation."
echo -e "Enjoy using ERPNext, HRMS, and Chat!"
echo -e "-----------------------------------------------------------------------------------------------${NC}"

# Message for Future Support Team
echo -e "${YELLOW}-----------------------------------------------------------------------------------------------"
echo -e "For future support, contact the support team at:"
echo -e "Phone: 002-01156483669"
echo -e "WhatsApp: https://wa.me/201156483669/"
echo -e "Include details about your system configuration and any issues you encounter."
echo -e "Thank you for choosing ERPNext!${NC}"
