#!/bin/sh
VER="v1.08b"
#============================================================================================ © 2021 Martineau v1.08
#
# Usage:    vnstat-install  {'install' [wan_interface] ['dev'] [email_script_name]| 'uninstall'}
#
#           vnstat-install     install
#                              Install 'vnstat' modules and scripts from Github
#
#           vnstat-install     install dev
#                              Install 'vnstat' modules and scripts from Github development branch
#
#           vnstat-install     install eth0
#                              Install 'vnstat' modules and scripts from Github development branch and override auto WAN interface detection
#
#           vnstat-install     install /jffs/scripts/my_emailer.sh
#                              Install 'vnstat' modules and scripts from Github and ovveride /send-vnstat.sh e-mail script
#
#           vnstat-install     install uninstall
#                              Delete 'vnstat' modules and scripts

ShowHelp() {
	awk '/^#==/{f=1} f{print; if (!NF) exit}' $0
}
# shellcheck disable=SC2034
ANSIColours() {
	cRESET="\e[0m";cBLA="\e[30m";cRED="\e[31m";cGRE="\e[32m";cYEL="\e[33m";cBLU="\e[34m";cMAG="\e[35m";cCYA="\e[36m";cGRA="\e[37m";cFGRESET="\e[39m"
	cBGRA="\e[90m";cBRED="\e[91m";cBGRE="\e[92m";cBYEL="\e[93m";cBBLU="\e[94m";cBMAG="\e[95m";cBCYA="\e[96m";cBWHT="\e[97m"
	aBOLD="\e[1m";aDIM="\e[2m";aUNDER="\e[4m";aBLINK="\e[5m";aREVERSE="\e[7m"
	aBOLDr="\e[21m";aDIMr="\e[22m";aUNDERr="\e[24m";aBLINKr="\e[25m";aREVERSEr="\e[27m"
	cWRED="\e[41m";cWGRE="\e[42m";cWYEL="\e[43m";cWBLU="\e[44m";cWMAG="\e[45m";cWCYA="\e[46m";cWGRA="\e[47m"
	cYBLU="\e[93;48;5;21m"
	cRED_="\e[41m";cGRE_="\e[42m"
	xHOME="\e[H";xERASE="\e[2J";xERASEDOWN="\e[J";xERASEUP="\e[1J";xCSRPOS="\e[s";xPOSCSR="\e[u";xERASEEOL="\e[K";xQUERYCSRPOS="\e[6n"
	xGoto="\e[Line;Columnf"
}
Get_WAN_IF_Name() {

	# echo $([ -n "$(nvram get wan0_pppoe_ifname)" ] && echo $(nvram get wan0_pppoe_ifname) || echo $(nvram get wan0_ifname))
	#   nvram get wan0_gw_ifname
	#   nvram get wan0_proto

	local IF_NAME=$(ip route | awk '/^default/{print $NF}')     # Should ALWAYS be 100% reliable ?

	local IF_NAME=$(nvram get wan0_ifname)                      # ...but use the NVRAM e.g. DHCP/Static ?

	# Usually this is probably valid for both eth0/ppp0e ?
	if [ "$(nvram get wan0_gw_ifname)" != "$IF_NAME" ];then
		local IF_NAME=$(nvram get wan0_gw_ifname)
	fi

	if [ ! -z "$(nvram get wan0_pppoe_ifname)" ];then
		local IF_NAME="$(nvram get wan0_pppoe_ifname)"          # PPPoE
	fi

	echo $IF_NAME

}
Download_file() {

	local FN=$1

	curl -# -L https://raw.githubusercontent.com/de-vnull/vnstat-on-merlin/${BRANCH}/scripts/$FN -o $INSTALL_DIR/$FN  && chmod 755 $INSTALL_DIR/$FN && dos2unix $INSTALL_DIR/$FN

}
#=============================================================Main==============================================================
Main() { true; }            # Syntax that is Atom Shellchecker compatible!

SNAME="${0##*/}"							# Script name

ANSIColours

INSTALL_DIR="/jffs/addons/vnstat.d"
BRANCH="main"																# v1.07

mkdir -p $INSTALL_DIR
mkdir -p /jffs/addons/vnstat-ui.d

# Help request ?
if [ "$1" == "help" ] || [ "$1" == "-h" ];then
	echo -e $cBWHT
	ShowHelp							# Show help
	echo -e $cRESET
	exit 0
fi

# Loop through the command args
while [ $# -gt 0 ];do    # v1.04 Process all command line args. . .

	if [ "$1" == "install" ] || [ "$1" == "uninstall" ] ;then
		ACTION=$1
	else
		if [ -f $1 ];then
			EMAIL_SCRIPT=$1         # assume this arg is the email script
		else

			# Allow retrieving files from the Github development branch
			if [ "${1:0:3}" == "dev" ];then										# v1.07
				BRANCH="development"
			else

				if [ ${#1} -le 5 ];then
				xxx=${1:1:3}
					if { [ "${1:0:3}" == "eth" ] || [ "${1:0:3}" == "ppp" ] || [ "${1:0:4}" == "vlan" ]; } && [ -n "$(ifconfig $1)" ];then	# v1.07
						WAN_IF=$1
					else
						echo -e "\a\n\tERROR: Invalid Interface '$1' prefix - e.g valid prefixed interfaces: 'eth0' or 'ppp0' or 'vlan2'"
						exit 99
					fi
				else
					echo -e "\a\n\tERROR: Invalid Interface '$1'"
					exit 98
				fi
			fi
		fi
	fi

	shift       # Check next set of parameters.

done

case $ACTION in

	install)																	# v1.07 {install ['dev']}

		logger -st "$0" $VER "Installing 'vnstat'...."

		logger -st "$0" "   Installing 'vnstat' Entware modules"
		echo -en $cBGRA 2>&1
		opkg install vnstat vnstati libjpeg-turbo imagemagick

		echo -en $cRESET

		logger -st "$0" "   Installing 'vnstat' scripts to $INSTALL_DIR from Github $BRANCH branch"   # v1.07 v1.04
		echo -en $cBGRA 2>&1

		# v1.06 Use Github repository rather than Bitbucket!
		Download_file "vnstat-stats"	"$BRANCH"			# v1.07
		Download_file "vnstat-ui"		"$BRANCH"			# v1.07
		Download_file "vnstat-ww.sh"	"$BRANCH"			# v1.07
		Download_file "send-vnstat"		"$BRANCH"			# v1.07
		Download_file "div-email.sh"    "$BRANCH"			# v1.07 v1.05

		echo -en $cRESET

		# Create Addons GUI Tab
		logger -st "$0" "   Creating Addons GUI TAB"
		echo -en $cBGRA 2>&1

		curl -# -L https://raw.githubusercontent.com/de-vnull/vnstat-on-merlin/${BRANCH}/scripts/vnstat-ui.asp -o /jffs/addons/vnstat-ui.d/vnstat-ui.asp && dos2unix /jffs/addons/vnstat-ui.d/vnstat-ui.asp
		echo -en $cRESET
		$INSTALL_DIR/vnstat-ui

		# Ensure Addon GUI tab will be created @boot ***v1.07 HACK moved to 'post-mount' ***
		#logger -st "$0" "   Adding 'vnstat-ui' Addons GUI TAB creation service-event (@boot)"
		#[ -z "$(grep "vnstat" /jffs/scripts/service-event)" ] && echo -e "$INSTALL_DIR/vnstat-ui & # vnstat Addon GUI" >> /jffs/scripts/service-event
		[ -n "$(grep "vnstat" /jffs/scripts/service-event)" ] && sed -i '/vnstat/d' /jffs/scripts/service-event		# v.1.07

		# Create cron jobs
		logger -st "$0" "   Creating cron jobs (e-mail cmd '$EMAIL_CMD')"
		if [ -z "$EMAIL_SCRIPT" ];then                  # v1.05 Use default or cloned Diversion script ONLY if installed
			EMAIL_CMD="$INSTALL_DIR/send-vnstat"
			[ -f /opt/share/diversion/.conf/emailpw.enc ] && EMAIL_CMD="$INSTALL_DIR/div-email.sh Vnstat-stats /home/root/vnstat.txt"   # v1.05
		else
			EMAIL_CMD=$EMAIL_SCRIPT" /home/root/vnstat.txt" # v1.04
		fi

		cru d vnstat_daily >/dev/null                   # v1.04
		cru d vnstat_update >/dev/null                  # v1.04
		cru a vnstat_update "*/13 * * * * /opt/bin/vnstat -u && sh $INSTALL_DIR/vnstat-ww.sh"                   # v1.04
		cru a vnstat_daily  "59 23 * * * /opt/bin/vnstat -u && sh $INSTALL_DIR/vnstat-stats && sh $EMAIL_CMD"   # v1.04

		logger -st "$0" "   Adding cron jobs to 'services-start'"
		[ -n "$(grep "vnstat" /jffs/scripts/services-start)" ] && sed -i '/vnstat/d' /jffs/scripts/services-start
		( echo -e "cru a vnstat_daily \"59 23 * * *   /opt/bin/vnstat -u && sh $INSTALL_DIR/vnstat-stats && sh $EMAIL_CMD\" # vnstat daily use report and email"    # v1.04
		  echo -e "cru a vnstat_update \"*/13 * * * * /opt/bin/vnstat -u && sh $INSTALL_DIR/vnstat-ww.sh\" # vnstat update UI addons tab"                           # v1.04
		) >> /jffs/scripts/services-start

		# v1.07 TEMPORARY Fix for broken GUI TAB links @boot until @dev_null implements 'vnstat-ui generate'
		#       HACK - but also create the GUI at the same time....
		logger -st "$0" "   Adding 'vnstat-ui' Addons GUI TAB creation (@boot) to 'post-mount' and refresh GUI broken links"
		[ -n "$(grep "vnstat" /jffs/scripts/post-mount)" ] && sed -i '/vnstat/d' /jffs/scripts/post-mount
		(
		  echo -e "(sh $INSTALL_DIR/vnstat-ui && /opt/bin/vnstat -u && sh $INSTALL_DIR/vnstat-stats && sh $INSTALL_DIR/vnstat-ww.sh) & # 'vnstat-ui generate' Hack" # v1.07
		) >> /jffs/scripts/post-mount

		# Customise vnstat configuration '/opt/etc/vnstat.conf'
		TXT="Auto detected WAN"             #v1.06
		[ -z "$WAN_IF" ] && WAN_IF=$(Get_WAN_IF_Name) || TXT="Manual override WAN"      # v1.06

		# Ensure 'Interface xxx' refers to current WAN interface
		logger -st "$0" "   Customising 'vnstat.conf' $TXT 'Interface" $WAN_IF"'"
		sed -i "/^Interface/ s/[^ ]*[^ ]/$WAN_IF/2" /opt/etc/vnstat.conf

		# Ensure GUI .asp refers to actual data files
		# <div><img src="/user/vnstat/vnstat_eth0_m.png" alt="Monthly"/></div>
		# <div><img src="/user/vnstat/vnstat_eth0_d.png" alt="Daily"/></div>
		# <div><img src="/user/vnstat/vnstat_eth0_h.png" alt="Hourly" /></div>
		# <div><img src="/user/vnstat/vnstat_eth0_s.png" alt="Hourly" /></div>
		# <div><img src="/user/vnstat/vnstat_eth0_t.png" alt="Hourly" /></div>
		logger -st "$0" "   Customising 'vnstat-ui.asp' $TXT GUI file references to '/vnstat_${WAN_IF}_?.png'"
		sed -i "s~/vnstat_eth0_~/vnstat_${WAN_IF}_~g" /jffs/addons/vnstat-ui.d/vnstat-ui.asp	# v1.08

		# Bug report unable to correctly detect Interface Bandwidth @ColinTaylor see http://www.snbforums.com/threads/vnstat-on-merlin-cli-ui-and-email-data-use-monitoring.70091/post-661241
		#    vnstatd[nnnn]: Monitoring: vlan2 (10 Mbit) br0 (1000 Mbit)
		#     vnstatd[nnnn]: Traffic rate for "vlan2" higher than set maximum 10 Mbit (60->83, r1030 t90), syncing
		logger -st "$0" "   Customising 'vnstat.conf' 'BandwidthDetection 0'"
		sed -i "/^BandwidthDetection/ s/[^ ]*[^ ]/0/2" /opt/etc/vnstat.conf        # v1.02 Disable BandwidthDetection detection 1->0

		# Ensure '[ -f "/opt/var/lib/vnstat.d/*" ] || vnstat -u -i xxx' refers to current WAN interface
		logger -st "$0" "   Customising 'S32vnstat/vnstat-ww.sh' scripts $TXT 'Interface" $WAN_IF"'"
		sed -i "s/\(vnstat -u -i\)\(.*$\)/\1 $WAN_IF/" /opt/etc/init.d/S32vnstat
		sed -i "s/eth0/$WAN_IF/g" $INSTALL_DIR/vnstat-ww.sh

		# Use Entware repository
		sed -i 's~mnt/your_drive_name/entware~opt~g' $INSTALL_DIR/vnstat-ww.sh
		sed -i 's~mnt/your_drive_name/entware~opt~g' $INSTALL_DIR/vnstat-stats

		# Start monitoring
		logger -st "$0" "   Requesting /opt/etc/init.d/S32vnstat.....will then pause for  5 seconds to generate data points"
		/opt/etc/init.d/S32vnstat restart

		sleep 1

		if [ -n "$(pidof vnstatd)" ];then

			logger -st "$0" "   .....paused for 5 seconds to generate data points"
			sleep 5                                                                 #v1.05

			# Create/Display Daily Summary report usually scheduled by cron @23:59
			#                (also used to populate the Addon GUI tab 'Vnstat/vnstati' section 'Vnstat CLI' otherwise you get a broken link!)
			echo -en $cBCYA
			/opt/bin/vnstat -u && sh $INSTALL_DIR/vnstat-stats              # v1.05
			$INSTALL_DIR/vnstat-ww.sh                                       # v1.06 Eliminate broken links?

			echo -e $cRESET
		else
			echo -e "\a\n\tCritical ERROR! 'vnstatd' NOT running?"
			logger -st "$0" "   Critical ERROR! 'vnstatd' NOT running?"
			exit 66
		fi

	;;
	uninstall)

		logger -st "$0" $VER "Uninstalling 'vnstat'...."

		# Kill vnstat process
		logger -st "$0" "   Stopping 'vnstat'"
		pidof vnstatd | while read -r "spid" && [ -n "$spid" ]; do
			kill "$spid"
		done

		logger -st "$0" "   Uninstalling 'vnstat' Entware modules"
		echo -en $cBGRA 2>&1
		#opkg remove vnstat vnstati libjpeg-turbo imagemagick --force-depends --force-removal-of-dependent-packages

		opkg remove vnstat vnstati imagemagick --force-depends --force-removal-of-dependent-packages    # v1.03

		echo -en $cRESET

		# Delete cron jobs
		logger -st "$0" "   Uninstalling cron jobs"     # v1.04
		cru d vnstat_daily >/dev/null                   # v1.04
		cru d vnstat_update >/dev/null                  # v1.04
		[ -n "$(grep "vnstat" /jffs/scripts/services-start)" ] && sed -i '/vnstat/d' /jffs/scripts/services-start

		# Remove Addons GUI Tab
		#logger -st "$0" "   Removing 'vnstat-ui' Addons GUI TAB creation from 'service-event' (@boot)"
		[ -n "$(grep "vnstat" /jffs/scripts/service-event)" ] && sed -i '/vnstat/d' /jffs/scripts/service-event
		if [ -n "$(grep "uninstall)" $INSTALL_DIR/vnstat-ui)" ];then    # v1.07 ***WON'T WORK UNTIL @dev_null adds 'uninstall' code ***
			logger -st "$0" "Removing Addons GUI TAB"
			$INSTALL_DIR/vnstat-ui uninstall        # v1.07
		fi

		logger -st "$0" "   Deleting directories '/jffs/addons/vnstat*' and configuration 'vnstat.conf'"
		[ -d /jffs/addons/vnstat-ui.d ] &&  { rm /jffs/addons/vnstat-ui.d/* >/dev/null 2>&1; rmdir /jffs/addons/vnstat-ui.d; }
		[ -d $INSTALL_DIR ] &&  { rm $INSTALL_DIR/* >/dev/null 2>&1; rmdir $INSTALL_DIR; }

		[ -f /opt/etc/vnstat.conf ] && rm /opt/etc/vnstat.conf


	   logger -st "$0" "   Uninstalling '$0'"
	   rm /jffs/scripts/$0       # v1.03
	;;
	*)

		echo -e "\a\nERROR unrecognised/missing arg.\n\n\tUsage: 'sh /jffs/scripts/vnstat-install.sh {install [wan_interface] [email_script] | uninstall'}\n"     # v1.04 v1.03

esac
