#!/opt/bin/sh
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
