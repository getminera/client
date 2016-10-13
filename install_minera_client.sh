#!/usr/bin/env bash
red=`tput setaf 1`
green=`tput setaf 2`
reset=`tput sgr0`

echo -e "-----\n${green}START Minera Install script${reset}\n-----\n"

echo -e "-----\n${green}Install extra packages${reset}\n-----\n"
apt-get update
apt-get install -y git

NEW_UUID=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)

echo -e "-----\n${green}Adding Minera user${reset}\n-----\n"
adduser minera --gecos "" --disabled-password
echo "minera:$NEW_UUID" | chpasswd

echo -e "-----\n${green}Adding groups to Minera${reset}\n-----\n"
usermod -a -G dialout,plugdev,tty minera

echo -e "-----\n${green}Adding sudoers configuration for www-data and minera users\n-----\n${reset}"
echo -e "\n#Minera settings\nminera ALL = (ALL) NOPASSWD: ALL" >> /etc/sudoers

MINERA_DIR="/opt/minera-client"
MINERA_ID=$1
if [ -z "$1" ]
  then
    MINERA_ID="zTkGRKl5DHq18NdT9jNyk/ujZAH7clk+K8r7ZAOj6Kk="
fi

echo -e "-----\n${green}Installing NVM & Node.js${reset}\n-----\n"
su minera -c "curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.32.0/install.sh | bash"
su minera -c "source /home/minera/.nvm/nvm.sh; nvm install stable"
NODE_PATH=`su minera -c "source /home/minera/.nvm/nvm.sh; nvm which stable"`
ln -s $NODE_PATH /usr/bin/node

echo -e "-----\n${green}Cloning Minera Client${reset}\n-----\n"
mkdir $MINERA_DIR
git clone https://github.com/getminera/client $MINERA_DIR
chown -R minera:minera $MINERA_DIR

echo -e "-----\n${green}Installing Node.js modules${reset}\n-----\n"
cd $MINERA_DIR
su minera -c "source /home/minera/.nvm/nvm.sh; npm install --production"

echo -e "-----\n${green}Adding Systemd startup script${reset}\n-----\n"
cat > /etc/systemd/system/minera-client.service <<EOL
[Service]
ExecStart=/usr/bin/node $MINERA_DIR/client.js
Restart=always
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=minera-client
User=minera
Group=minera
Environment=MINERA_ID=$MINERA_ID

[Install]
WantedBy=multi-user.target
EOL

echo -e "-----\n${green}Starting Minera Client${reset}\n-----\n"
systemctl start minera-client

if [ "$MINERA_ID" == "zTkGRKl5DHq18NdT9jNyk/ujZAH7clk+K8r7ZAOj6Kk=" ]; then
	echo -e "${red}ATTENTION${reset} You did not add your ${red}MINERA_ID${reset}\nYou absolutely need to change it in\n    ${green}/etc/systemd/system/minera-client.service${reset}\nand restart the service with\n    ${green}sudo systemctl restart minera-client${reset}"
fi

echo -e "\n-----\n${green}All DONE. Check your system on https://app.getminera.com${reset}\n-----\n"