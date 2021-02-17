#!/bin/sh

VER="v1.03"

Download_file() {

    local FN=$(basename $1)

#    curl https://bitbucket.org/vnstat-on-merlin-v001/vnstat_on_merlin/raw/$1 -o /jffs/addons/vnstat.d/$FN  && chmod 755 /jffs/addons/vnstat.d/$FN && dos2unix /jffs/addons/vnstat.d/$FN
#    curl -s "https://raw.githubusercontent.com/Adamm00/IPSet_ASUS/master/firewall.sh" -o "/jffs/scripts/firewall" && chmod 755 /jffs/scripts/firewall && sh /jffs/scripts/firewall install
     curl 
}

# BITBUCKET_UUID="8f3d1a8e3bc83827907bad076a0859c00841c836"        # v1.02

mkdir -p /jffs/addons/vnstat.d
mkdir -p /jffs/addons/vnstat-ui.d

case $1 in

    install)
	
		logger -st "$0" $VER "Installing 'vnstat'...."

        [ -n "$2" ] && WAN_IF=$2

		logger -st "$0" "   Installing 'vnstat' Entware modules"
        opkg install vnstat vnstati libjpeg-turbo imagemagick

        Download_file "${BITBUCKET_UUID}/scripts/send-vnstat"
        Download_file "${BITBUCKET_UUID}/scripts/vnstat-stats"
        Download_file "${BITBUCKET_UUID}/scripts/vnstat-ui"
        Download_file "${BITBUCKET_UUID}/scripts/vnstat-ww.sh"

        curl "https://bitbucket.org/vnstat-on-merlin-v001/vnstat_on_merlin/raw/${BITBUCKET_UUID}/scripts/vnstat-ui.asp" -o /jffs/addons/vnstat-ui.d/vnstat-ui.asp && dos2unix /jffs/addons/vnstat-ui.d/vnstat-ui.asp

        # Create Addons GUI Tab
		logger -st "$0" "   Creating Addons GUI TAB"
        /jffs/addons/vnstat.d/vnstat-ui
        # Ensure Addon GUI tab will be created @boot
		logger -st "$0" "   Adding 'vnstat-ui' Addons GUI TAB creation service-event (@boot)"
        [ -z "$(grep "vnstat" /jffs/scripts/service-event)" ] && echo -e "/jffs/addons/vnstat.d/vnstat-ui & # vnstat Addon GUI" >> /jffs/scripts/service-event

        # Create cron jobs
		logger -st "$0" "   Adding cron jobs to services-start"
        if [ -z "$(grep "vnstat" /jffs/scripts/services-start)" ];then
            ( echo -e "cru a vnstat_daily \"59 23 * * * /opt/bin/vnstat -u && sh /jffs/addons/vnstat.d/vnstat-stats && sh /jffs/addons/vnstat.d/send-vnstat\" # vnstat daily use report and email"
              echo -e "cru a vnstat_update \"/13  * * * /opt/bin/vnstat -u && sh /jffs/addons/vnstat.d/vnstat-ww.sh\" # vnstat update UI addons tab"
            ) >> /jffs/scripts/services-start

        fi

		TXT="Auto detected (nvram get wan0_ifname)"
        [ -z "$WAN_IF" ] && WAN_IF=$(nvram get wan0_ifname) || TXT="Manual override"

        # Ensure 'Interface xxx' refers to current WAN interface
		logger -st "$0" "   Customising 'vnstat.conf' $TXT 'Interface" $WAN_IF"'"
        sed -i "/^Interface/ s/[^ ]*[^ ]/$WAN_IF/2" /opt/etc/vnstat.conf
      
        # Bug report unable to correctly detect Interface Bandwidth @ColinTaylor see http://www.snbforums.com/threads/vnstat-on-merlin-cli-ui-and-email-data-use-monitoring.70091/post-661241
        #    vnstatd[nnnn]: Monitoring: vlan2 (10 Mbit) br0 (1000 Mbit)
        #     vnstatd[nnnn]: Traffic rate for "vlan2" higher than set maximum 10 Mbit (60->83, r1030 t90), syncing
        logger -st "$0" "   Customising 'vnstat.conf' 'BandwidthDetection 0'"
		sed -i "/^BandwidthDetection/ s/[^ ]*[^ ]/0/2" /opt/etc/vnstat.conf        # v1.02 Disable BandwidthDetection detection 1->0

        # Ensure '[ -f "/opt/var/lib/vnstat.d/*" ] || vnstat -u -i xxx' refers to current WAN interface
		logger -st "$0" "   Customising 'S32vnstat/vnstat-ww.sh' scripts $TXT 'Interface" $WAN_IF"'"
        sed -i "s/\(vnstat -u -i\)\(.*$\)/\1 $WAN_IF/" /opt/etc/init.d/S32vnstat
        sed -i "s/eth0/$WAN_IF/g" /jffs/addons/vnstat.d/vnstat-ww.sh

        # Use Entware repository
        sed -i 's~mnt/your_drive_name/entware~opt~g' /jffs/addons/vnstat.d/vnstat-ww.sh
        sed -i 's~mnt/your_drive_name/entware~opt~g' /jffs/addons/vnstat.d/vnstat-stats

        /opt/etc/init.d/S32vnstat restart

    ;;
    uninstall)

		logger -st "$0" $VER "Uninstalling 'vnstat'...."
		
		logger -st "$0" "   Stopping 'vnstat'"
        # Kill vnstat process
        pidof vnstatd | while read -r "spid" && [ -n "$spid" ]; do
            kill "$spid"
        done

		logger -st "$0" "   Uninstalling 'vnstat' Entware modules"
        #opkg remove vnstat vnstati libjpeg-turbo imagemagick --force-depends --force-removal-of-dependent-packages
		opkg remove vnstat vnstati imagemagick --force-depends --force-removal-of-dependent-packages	# v1.03

        if [ -n "$(grep "vnstat" /jffs/scripts/services-start)" ];then
            sed -i '/vnstat/d' /jffs/scripts/services-start
        fi

		logger -st "$0" "   Deleting directories '/jffs/addons/vnstat*' and configuration 'vnstat.conf'"
        [ -d /jffs/addons/vnstat-ui.d ] &&  { rm /jffs/addons/vnstat-ui.d/* >/dev/null 2>&1; rmdir /jffs/addons/vnstat-ui.d; }
        [ -d /jffs/addons/vnstat.d ] &&  { rm /jffs/addons/vnstat.d/* >/dev/null 2>&1; rmdir /jffs/addons/vnstat.d; }

        [ -f /opt/etc/vnstat.conf ] && rm /opt/etc/vnstat.conf

        # Remove Addons tab
        # TBA
		#logger -st "$0" "Removing Addons GUI TAB"

	   logger -st "$0" "   Uninstalling '$0'"
       rm /jffs/scripts/$0       # v1.03
    ;;
    *)

        echo -e "\a\nERROR unrecognised/missing arg.\n\n\tUsage: 'sh /jffs/scripts/vnstat-install.sh {install [wan_interface] | uninstall'}\n"     # v1.03
  
esac
