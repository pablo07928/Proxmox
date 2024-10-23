run 
bash -c "$(wget -qLO - https://github.com/pablo07928/Proxmox/raw/main/scripts/ProxmoxSetup.sh)"

Kill all containers listed in /tmp/ctlist
bash -c "$(wget -qLO - https://github.com/pablo07928/Proxmox/raw/main/scripts/killall.sh)"


SabNZBd install:

bash -c "$(wget -qLO - https://github.com/pablo07928/Proxmox/raw/main/scripts/Sabnzbd.sh)"

Sonnar install:

bash -c "$(wget -qLO - https://github.com/pablo07928/Proxmox/raw/main/scripts/Sonarr.sh)"

Radarr install:

bash -c "$(wget -qLO - https://github.com/pablo07928/Proxmox/raw/main/scripts/Radarr.sh)"
