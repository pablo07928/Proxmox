#!/bin/bash

bash -c "$(wget -qLO - https://github.com/tteck/Proxmox/raw/main/ct/sabnzbd.sh)"

bash -c "$(wget -qLO - https://github.com/pablo07928/Proxmox/raw/main/AddSharestoLXC.sh)"

systemctl stop sabnzbd
cp /media/scripts/sabnzbd/sabnzbd.ini /root/sabnzbd/sabnzbd.ini
apt install iptables -y
iptables -t nat -A PREROUTING -p tcp --dport 80 -j REDIRECT --to-port 8080
systemctl start sabnzbd
