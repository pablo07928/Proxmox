#!/bin/bash

#VARS
FILES=(black.list blacklist.txt regex.list whitelist.txt mydomain.lan.list dhcp.leases) #list of files you want to sync
PIHOLEDIR=/etc/pihole #working dir of pihole
PIHOLE2= #IP of 2nd PiHole
HAUSER=root #user of second pihole

#LOOP FOR FILE TRANSFER
RESTART=0 # flag determine if service restart is needed
for FILE in ${FILES[@]}
do
  if [[ -f $PIHOLEDIR/$FILE ]]; then
  RSYNC_COMMAND=$(rsync -ai $PIHOLEDIR/$FILE $HAUSER@$PIHOLE2:$PIHOLEDIR)
    if [[ -n "${RSYNC_COMMAND}" ]]; then
      # rsync copied changes
      RESTART=1 # restart flagged
     # else
       # no changes
     fi
  # else
    # file does not exist, skipping
  fi
done


FILE="adlists.list"
RSYNC_COMMAND=$(rsync -ai $PIHOLEDIR/$FILE $HAUSER@$PIHOLE2:$PIHOLEDIR)
if [[ -n "${RSYNC_COMMAND}" ]]; then
  # rsync copied changes, update GRAVITY
  ssh $HAUSER@$PIHOLE2 "pihole -g"
# else
  # no changes
fi


#DHCP Files

FILE="/etc/dnsmasq.d/04-pihole-static-dhcp.conf"
RSYNC_COMMAND=$(rsync -ai $FILE $HAUSER@$PIHOLE2:$FILE)
if [[ -n "${RSYNC_COMMAND}" ]]; then
  # rsync copied changes, update GRAVITY
  ssh $HAUSER@$PIHOLE2 "pihole -g"
# else
  # no changes
fi

FILE="/etc/dnsmasq.d/02-pihole-dhcp.conf"
RSYNC_COMMAND=$(rsync -ai $FILE $HAUSER@$PIHOLE2:$FILE)
if [[ -n "${RSYNC_COMMAND}" ]]; then
  # rsync copied changes, update GRAVITY
  ssh $HAUSER@$PIHOLE2 "pihole -g"
# else
  # no changes
fi

if [ $RESTART == "1" ]; then
  # INSTALL FILES AND RESTART pihole
  ssh $HAUSER@$PIHOLE2 "service pihole-FTL stop"
  ssh $HAUSER@$PIHOLE2 "pkill pihole-FTL"
  ssh $HAUSER@$PIHOLE2 "service pihole-FTL start"
fi
            

#END OF SCRIPT