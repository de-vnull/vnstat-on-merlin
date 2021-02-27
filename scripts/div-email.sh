#!/opt/bin/sh
# ver=0.9.3
# Adapted from elorimer snbforum's script leveraging Diversion email credentials - agreed by thelonelycoder as well
# This script is used to email the daily/weekly/monthly vnstat usage for the Vnstat on Merlin script and UI - by dev_null at snbforums
# It can also be used to email other text-derived reports by passing the mailbody parameter which would be the path to a text file
#Parameters passed#
mailsubject=$1
mailbody=$2

# Email settings (mail envelope) #
. /opt/share/diversion/.conf/email.conf
PASSWORD=$(openssl aes-256-cbc -d  -in /opt/share/diversion/.conf/emailpw.enc -pass pass:ditbabot,isoi)

#Build email
    echo "From: \"$FRIENDLY_ROUTER_NAME\" <$FROM_ADDRESS>" >/tmp/mail.txt
    echo "To: \"$TO_NAME\" <$TO_ADDRESS>" >>/tmp/mail.txt
    echo "Subject: $mailsubject "as of $(date +"%H.%M on %F") >>/tmp/mail.txt
    echo "Date: $(date -R)" >>/tmp/mail.txt
    echo >>/tmp/mail.txt
    echo " $(cat $mailbody)" >>/tmp/mail.txt
  

#Send Email
#First parameter is subject, second is file to send
/usr/sbin/curl --url $PROTOCOL://$SMTP:$PORT \
        --mail-from "$FROM_ADDRESS" --mail-rcpt "$TO_ADDRESS" \
                    --upload-file /tmp/mail.txt \
                    --ssl-reqd \
                    --user "$USERNAME:$PASSWORD" $SSL_FLAG
          
rm /tmp/mail.txt
logger -s -t div-email email event processed
