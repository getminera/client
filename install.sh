#!/usr/bin/env bash
red=`tput setaf 1`
green=`tput setaf 2`
reset=`tput sgr0`
INIT="notfound"

[[ `/sbin/init --version` =~ upstart ]] && INIT="upstart" || INIT=INIT
[[ `systemctl` =~ -\.mount ]] && INIT="systemd" || INIT=INIT

echo $INIT

echo -e "-----\n${green}START Minera Install script${reset}\n-----\n"

echo -e "-----\n${green}Install extra packages${reset}\n-----\n"
sudo apt-get update
sudo apt-get install -y git

NEW_UUID=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)

echo -e "-----\n${green}Adding Minera user${reset}\n-----\n"
sudo adduser minera --gecos "" --disabled-password
echo "minera:$NEW_UUID" | chpasswd

echo -e "-----\n${green}Adding groups to Minera${reset}\n-----\n"
sudo usermod -a -G dialout,plugdev,tty minera

echo -e "-----\n${green}Adding sudoers configuration minera user\n-----\n${reset}"
echo -e "\n#Minera settings\nminera ALL = (ALL) NOPASSWD: ALL" | sudo tee --append /etc/sudoers

MINERA_DIR="/opt/minera-client"
MINERA_ID=$1
if [ -z "$1" ]
  then
    MINERA_ID="zTkGRKl5DHq18NdT9jNyk/ujZAH7clk+K8r7ZAOj6Kk="
fi

echo -e "-----\n${green}Installing NVM & Node.js${reset}\n-----\n"
sudo su minera -c "curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.32.0/install.sh | bash"
sudo su minera -c "source /home/minera/.nvm/nvm.sh; nvm install stable"
NODE_PATH=`sudo su minera -c "source /home/minera/.nvm/nvm.sh; nvm which stable"`
sudo ln -s $NODE_PATH /usr/bin/node

echo -e "-----\n${green}Cloning Minera Client${reset}\n-----\n"
sudo mkdir $MINERA_DIR
sudo git clone https://github.com/getminera/client $MINERA_DIR
sudo chown -R minera:minera $MINERA_DIR

echo -e "-----\n${green}Installing Node.js modules${reset}\n-----\n"
cd $MINERA_DIR
sudo su minera -c "source /home/minera/.nvm/nvm.sh; npm install --production"

if [ "$INIT" == "systemd" ]; then
echo -e "-----\n${green}Adding Systemd startup script${reset}\n-----\n"
cat > /tmp/minera-client.service <<EOL
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
sudo mv /tmp/minera-client.service /etc/systemd/system/minera-client.service

echo -e "-----\n${green}Starting Minera Client${reset}\n-----\n"
sudo systemctl daemon-reload
sudo systemctl restart minera-client

if [ "$MINERA_ID" == "zTkGRKl5DHq18NdT9jNyk/ujZAH7clk+K8r7ZAOj6Kk=" ]; then
    echo -e "${red}ATTENTION${reset} You did not add your ${red}MINERA_ID${reset}\nYou absolutely need to change it in\n    ${green}/etc/systemd/system/minera-client.service${reset}\nand restart the service with\n    ${green}sudo systemctl restart minera-client${reset}"
fi
fi

if [ "$INIT" == "upstart" ]; then
    echo "IS UPSTART"
fi

if [ "$INIT" == "notfound" ]; then
    echo "IS NOTOFUND"
fi

echo -e "\n-----\n${green}All DONE. Check your system on https://app.getminera.com${reset}\n-----\n"

