#!/bin/sh
# ver=1.0.0
# This script is used to email the daily/weekly/monthly vnstat usage for the Vnstat on Merlin script and UI - by dev_null at snbforums
# the use of the div-email script is preferred as that script uses Diversions encrypted email password - this script should be used only if Diversion is not being used
#
# the next line is a reminder in the syslog that credentials have not been set up - comment out this line once credential have been entered
logger -s -t vnstat-email vnstat email setup not completed - check send-vnstat and update credentials
#
#
FROM="Router vnstat report"
AUTH="username@gmail.com"
PASS="userpassword"
TO="recepient@gmail.com"
SUBJECT="VNSTAT report"
FRIENDLY_ROUTER_NAME=Your router friendly name

makemime /home/root/vnstat.txt
# makemime -c "image/png" -a "Content-Disposition: attachment" -o /home/root/summary3.png /home/root/summary3.png
makemime -a"Subject: $FRIENDLY_ROUTER_NAME vnstat Stats at $(date +"%H.%M on %F")" -a"From: $FROM" -o /home/root/output.msg /home/root/vnstat.txt

cat /home/root/output.msg | sendmail -H"exec openssl s_client -quiet \
-CAfile /jffs/configs/Equifax_Secure_Certificate_Authority.pem \
-connect smtp.gmail.com:587 -tls1 -starttls smtp" \
-f"$FROM" \
-au"$AUTH" -ap"$PASS" $TO

logger -s -t vnstat-email vnstat email complete

rm  /home/root/vnstat.txt
