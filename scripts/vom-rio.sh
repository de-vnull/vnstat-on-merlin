#!/bin/sh
clear
# Script variables #
readonly SCRIPT_NAME="vom-rio"
readonly SCRIPT_VERSION="v4.30a"
# colors
RED='\033[0;31m'
YEL='\033[0;33m'
#BOLD='\033[0;1m'
NC='\033[0m' # No Color
printf "\\n                       \033[5mVnstat on Merlin alpha/beta1 removal script\033[0m"
printf "\\n${RED}                                by dev_null at snbforums${NC}\n"
printf "                                     v. 4.30a"
printf "\\n\\n\\nThis script is used ONLY when removing alpha/beta1 or self install of Vnstat on Merlin."
printf "\\n${RED}Do not use it on beta2 or later.${NC} This script will NOT delete any existing vnstat database files.\\n"
printf "Are you sure you want to remove this setup...(type YES to continue, any other key to quit):  "
read -r CONDITION

if [ "$CONDITION" = "YES" ]; then
	echo
	logger -st vos-rio "Uninstalling 'VoM alpha/beta1/manual version'...."
	# Kill vnstat - probably not necessary, but better safe
	logger -st vom-rio "Stopping 'vnstatd'"
	/opt/etc/init.d/S32vnstat stop
	killall vnstatd

	# Delete cron jobs
	logger -st vom-rio "Removing cron jobs..."
	cru d vnstat_daily
	cru d vnstat_update
	# Delete vnstat activities from the various startup scripts
	logger -st vom-rio "Removing vnstat activities from scripts..."
	grep "vnstat_daily" /jffs/scripts/service-event && sed -i '/vnstat_daily/d' /jffs/scripts/service-event 2> /dev/nul
	grep "vnstat_update" /jffs/scripts/service-event && sed -i '/vnstat_update/d' /jffs/scripts/service-event 2> /dev/null
	grep "vnstat_daily" /jffs/scripts/services-start && sed -i '/vnstat_daily/d' /jffs/scripts/services-start 2> /dev/null
	grep "vnstat_update" /jffs/scripts/services-start && sed -i '/vnstat_update/d' /jffs/scripts/services-start 2> /dev/null
	grep "vnstat-ui" /jffs/scripts/post-mount && sed -i '/vnstat-ui/d' /jffs/scripts/post-mount 2> /dev/null
	# Now remove the directories and files associated with the alpha/beta1/manual installations
	logger -st vom-rio "Deleting directories '/jffs/addons/vnstat*' and other un-needed files - no database files removed"
	rm -rf /jffs/addons/vnstat-ui.d
	rm -rf /jffs/addons/vnstat.d
	rm -f /jffs/scripts/send-vnstat.sh
	rm -f /jffs/scripts/vnstat-stats
	rm -f /jffs/scripts/vnstat-ui
	rm -f /jffs/scripts/vnstat-ww.sh
	rm -f /jffs/scripts/vom-rio.sh
	rm -f /jffs/scripts/vnstat-install.sh
fi
# Wrap up
logger -st vom-rio "VoM RIO script completed."
printf "\\n\\n${YEL}As long as you typed YES, removal completed - no database files removed. Now run the latest install!${NC}\\n\\n"
printf "\\n\033[5mPlease manually reboot to finish removing all in-use files.\033[0m\\n"
printf "${RED}Until reboot is completed - vnstat will NOT track data use!${NC}\\n"
sleep 5

# reboot # not used at this time - manual reboot required
