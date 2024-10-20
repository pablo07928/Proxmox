#!/bin/bash

bash -c "$(wget -qLO - https://github.com/tteck/Proxmox/raw/main/ct/sabnzbd.sh)"

bash -c "$(wget -qLO - https://github.com/pablo07928/Proxmox/raw/main/AddSharestoLXC.sh)"

pct exec $currrent_lxc_id systemctl stop sabnzbd
pct exec $currrent_lxc_id cp /media/scripts/sabnzbd/sabnzbd.ini /root/sabnzbd/sabnzbd.ini
pct exec $currrent_lxc_id apt install iptables -y
pct exec $currrent_lxc_id iptables -t nat -A PREROUTING -p tcp --dport 80 -j REDIRECT --to-port 8080
pct exec $currrent_lxc_id systemctl start sabnzbd
pct exec $currrent_lxc_id reboot now
