#!/bin/bash


#bash -c "$(wget -qLO - https://github.com/tteck/Proxmox/raw/main/ct/sabnzbd.sh)"

bash -c "$(wget -qLO - https://github.com/pablo07928/Proxmox/raw/main/AddSharestoLXC.sh)"
echo "load source"
source /etc/pve/lxc/currentid.sh
echo "the current id is:"$current_lxc_id
echo "pct exec $current_lxc_id systemctl stop sabnzbd"
pct exec $current_lxc_id systemctl stop sabnzbd
echo " pct exec $current_lxc_id cp /media/scripts/sabnzbd/sabnzbd.ini /root/sabnzbd/sabnzbd.ini"
pct exec $current_lxc_id cp /media/scripts/sabnzbd/sabnzbd.ini /root/sabnzbd/sabnzbd.ini
echo "pct exec $current_lxc_id apt install iptables -y"
pct exec $current_lxc_id apt install iptables -y
echo "pct exec $current_lxc_id iptables -t nat -A PREROUTING -p tcp --dport 80 -j REDIRECT --to-port 8080"
pct exec $current_lxc_id iptables -t nat -A PREROUTING -p tcp --dport 80 -j REDIRECT --to-port 8080
pct exec $current_lxc_id systemctl start sabnzbd
pct exec $current_lxc_id reboot now
rm /etc/pve/lxc/currentid.sh

