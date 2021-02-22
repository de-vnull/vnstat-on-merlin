#!/bin/sh

#################################################################
##                                                             ##
##          vnstat and vnstati data usage statistics           ##
##                     version 0.9.0 (beta)                    ##
##            Created by dev_null with assistance              ##
##         from JackYaz - cribbing from his script base        ##
##                                                             ##
#################################################################

### Start of script variables ###
readonly SCRIPT_NAME="vnstat-on-merlin"
readonly SCRIPT_VERSION="v0.9.0"
readonly SCRIPT_BRANCH="master"
readonly SCRIPT_DIR="/jffs/addons/$SCRIPT_NAME.d"
readonly SCRIPT_WEBPAGE_DIR="$(readlink /www/user)"
readonly SCRIPT_WEB_DIR="$SCRIPT_WEBPAGE_DIR/$SCRIPT_NAME"
readonly SHARED_DIR="/jffs/addons/shared-jy"
readonly SHARED_WEB_DIR="$SCRIPT_WEBPAGE_DIR/shared-jy"
[ -z "$(nvram get odmpid)" ] && ROUTER_MODEL=$(nvram get productid) || ROUTER_MODEL=$(nvram get odmpid)
### End of script variables ###

### Start of output format variables ###
readonly CRIT="\\e[41m"
readonly ERR="\\e[31m"
readonly WARN="\\e[33m"
readonly PASS="\\e[32m"
### End of output format variables ###

# $1 = print to syslog, $2 = message to print, $3 = log level
Print_Output(){
	if [ "$1" = "true" ]; then
		logger -t "$SCRIPT_NAME" "$2"
		printf "\\e[1m$3%s: $2\\e[0m\\n\\n" "$SCRIPT_NAME"
	else
		printf "\\e[1m$3%s: $2\\e[0m\\n\\n" "$SCRIPT_NAME"
	fi
}

Firmware_Version_Check(){
	if nvram get rc_support | grep -qF "am_addons"; then
		return 0
	else
		return 1
	fi
}


############################################################################

Create_Dirs(){
	if [ ! -d "$SCRIPT_DIR" ]; then
		mkdir -p "$SCRIPT_DIR"
	fi
	
	if [ ! -d "$SHARED_DIR" ]; then
		mkdir -p "$SHARED_DIR"
	fi
	
	if [ ! -d "$SCRIPT_WEBPAGE_DIR" ]; then
		mkdir -p "$SCRIPT_WEBPAGE_DIR"
	fi
	
	if [ ! -d "$SCRIPT_WEB_DIR" ]; then
		mkdir -p "$SCRIPT_WEB_DIR"
	fi
}

Get_WebUI_Page(){
	MyPage="none"
	for i in 1 2 3 4 5 6 7 8 9 10; do
		page="/www/user/user$i.asp"
		if [ -f "$page" ] && [ "$(md5sum < "$1")" = "$(md5sum < "$page")" ]; then
			MyPage="user$i.asp"
			return
		elif [ "$MyPage" = "none" ] && [ ! -f "$page" ]; then
			MyPage="user$i.asp"
		fi
	done
}

Mount_WebUI(){
	Get_WebUI_Page "$SCRIPT_DIR/vnstat-ui.asp"
	if [ "$MyPage" = "none" ]; then
		Print_Output true "Unable to mount $SCRIPT_NAME WebUI page, exiting" "$CRIT"
		Clear_Lock
		exit 1
	fi
	Print_Output true "Mounting $SCRIPT_NAME WebUI page as $MyPage" "$PASS"
	cp -f "$SCRIPT_DIR/vnstat-ui.asp" "$SCRIPT_WEBPAGE_DIR/$MyPage"
	echo "vnstat-ui" > "$SCRIPT_WEBPAGE_DIR/$(echo $MyPage | cut -f1 -d'.').title"
	
	if [ "$(uname -o)" = "ASUSWRT-Merlin" ]; then
		if [ ! -f /tmp/index_style.css ]; then
			cp -f /www/index_style.css /tmp/
		fi
		
		if ! grep -q '.menu_Addons' /tmp/index_style.css ; then
			echo ".menu_Addons { background: url(ext/shared-jy/addons.png); }" >> /tmp/index_style.css
		fi
		
		umount /www/index_style.css 2>/dev/null
		mount -o bind /tmp/index_style.css /www/index_style.css
		
		if [ ! -f /tmp/menuTree.js ]; then
			cp -f /www/require/modules/menuTree.js /tmp/
		fi
		
		sed -i "\\~$MyPage~d" /tmp/menuTree.js
		
		if ! grep -q 'menuName: "Addons"' /tmp/menuTree.js ; then
			lineinsbefore="$(( $(grep -n "exclude:" /tmp/menuTree.js | cut -f1 -d':') - 1))"
			sed -i "$lineinsbefore"'i,\n{\nmenuName: "Addons",\nindex: "menu_Addons",\ntab: [\n{url: "ext/shared-jy/redirect.htm", tabName: "Help & Support"},\n{url: "NULL", tabName: "__INHERIT__"}\n]\n}' /tmp/menuTree.js
		fi
		
		if ! grep -q "javascript:window.open('/ext/shared-jy/redirect.htm'" /tmp/menuTree.js ; then
			sed -i "s~ext/shared-jy/redirect.htm~javascript:window.open('/ext/shared-jy/redirect.htm','_blank')~" /tmp/menuTree.js
		fi
		sed -i "/url: \"javascript:window.open('\/ext\/shared-jy\/redirect.htm'/i {url: \"$MyPage\", tabName: \"Vnstat/vnstati\"}," /tmp/menuTree.js
		
		umount /www/require/modules/menuTree.js 2>/dev/null
		mount -o bind /tmp/menuTree.js /www/require/modules/menuTree.js
	fi
}

Create_Dirs
Mount_WebUI

vnstat_ww(){
	# This script is used to refresh the daily/weekly/monthly vnstati - images - usage for the Vnstat on Merlin UI - by dev_null at snbforums
	# Adapted from http://code.google.com/p/x-wrt/source/browse/trunk/package/webif/files/www/cgi-bin/webif/graphs-vnstat.sh
	# mkdir /www/user/vnstat && cp /jffs/scripts/vnstat.htm /www/user/vnstat/vnstat.htm # not needed for Vnstat on Merlin
	logger -s -t vnstats vnstati updating stats for UI
	vnstat -u
	#
	WWW_D=/www/user/vnstat # output images to here
	LIB_D=/opt/var/lib/vnstat # db location - verify matches your install
	BIN=/opt/bin/vnstati  # which vnstati - verify matches your install
	#
	outputs="s h d t m hs"   # what images to generate
	#
	# Sanity checks
	[ -d "$WWW_D" ] || mkdir -p "$WWW_D" # make the folder if it dont exist.
	#
	# You might want to setup a link if it dont exist.
	# [ -L /www/vnstat ] || ln -sf /www/vnstat /www/user/
	# was /tmp/www/
	#
	# End of config changes
	interfaces="eth0"
	# was "$(ls -1 $LIB_D)"

	if [ -z "$interfaces" ]; then
	    echo "No database found, nothing to do."
	    echo "A new database can be created with the following command: "
	    echo "    vnstat -u -i eth0"
	    exit 0
	else
	    for interface in $interfaces ; do
	        for output in $outputs ; do
	            $BIN -${output} -i $interface -o $WWW_D/vnstat_${output}.png
	        done
	    done
	fi
}

vnstat_stats(){
	# This script is used to create the daily/weekly/monthly vnstat usage for the Vnstat on Merlin script and UI - by dev_null at snbforums
	printf "\\nVnstats as of:\\n%s" "$(date)" >> /home/root/vnstat.txt
	/opt/bin/vnstat -m >> /home/root/vnstat.txt
	/opt/bin/vnstat -w >> /home/root/vnstat.txt
	/opt/bin/vnstat -d >> /home/root/vnstat.txt
	echo >> /home/root/vnstat.txt
	cat /home/root/vnstat.txt
	cat /home/root/vnstat.txt | convert -font DejaVu-Sans-Mono -channel RGB -negate label:@- /tmp/var/wwwext/vnstat/vnstat.png
	logger -s -t vnstat_totals summary generated
}
