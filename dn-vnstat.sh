#!/bin/sh

#################################################
##                                             ##
##  vnstat and vnstati data usage statistics   ##
##              for AsusWRT-Merlin             ##
##                                             ##
##              Created by dev_null            ##
##                                             ##
#################################################

########         Shellcheck directives     ########
# shellcheck disable=SC1091
# shellcheck disable=SC2018
# shellcheck disable=SC2019
###################################################

### Start of script variables ###
readonly SCRIPT_NAME="dn-vnstat"
readonly SCRIPT_VERSION="v0.9.4"
SCRIPT_BRANCH="main"
SCRIPT_REPO="https://raw.githubusercontent.com/de-vnull/vnstat-on-merlin/$SCRIPT_BRANCH"
readonly SCRIPT_DIR="/jffs/addons/$SCRIPT_NAME.d"
readonly SCRIPT_WEBPAGE_DIR="$(readlink /www/user)"
readonly SCRIPT_WEB_DIR="$SCRIPT_WEBPAGE_DIR/$SCRIPT_NAME"
readonly IMAGE_OUTPUT_DIR="$SCRIPT_DIR/images"
readonly SHARED_DIR="/jffs/addons/shared-jy"
readonly SHARED_REPO="https://raw.githubusercontent.com/jackyaz/shared-jy/master"
readonly SHARED_WEB_DIR="$SCRIPT_WEBPAGE_DIR/shared-jy"
readonly VNSTAT_COMMAND="vnstat --config $SCRIPT_DIR/vnstat.conf"
readonly VNSTATI_COMMAND="vnstati --config $SCRIPT_DIR/vnstat.conf"
readonly ENABLE_EMAIL_FILE="$SCRIPT_DIR/.emailenabled"
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

### Check firmware version contains the "am_addons" feature flag ###
Firmware_Version_Check(){
	if nvram get rc_support | grep -qF "am_addons"; then
		return 0
	else
		return 1
	fi
}

### Create "lock" file to ensure script only allows 1 concurrent process for certain actions ###
### Code for these functions inspired by https://github.com/Adamm00 - credit to @Adamm ###
Check_Lock(){
	if [ -f "/tmp/$SCRIPT_NAME.lock" ]; then
		ageoflock=$(($(date +%s) - $(date +%s -r /tmp/$SCRIPT_NAME.lock)))
		if [ "$ageoflock" -gt 600 ]; then
			Print_Output true "Stale lock file found (>600 seconds old) - purging lock" "$ERR"
			kill "$(sed -n '1p' /tmp/$SCRIPT_NAME.lock)" >/dev/null 2>&1
			Clear_Lock
			echo "$$" > "/tmp/$SCRIPT_NAME.lock"
			return 0
		else
			Print_Output true "Lock file found (age: $ageoflock seconds)" "$ERR"
			if [ -z "$1" ]; then
				exit 1
			else
				if [ "$1" = "webui" ]; then
					echo 'var vnstatstatus = "LOCKED";' > /tmp/detect_vnstat.js
					exit 1
				fi
				return 1
			fi
		fi
	else
		echo "$$" > "/tmp/$SCRIPT_NAME.lock"
		return 0
	fi
}

Clear_Lock(){
	rm -f "/tmp/$SCRIPT_NAME.lock" 2>/dev/null
	return 0
}
############################################################################

### Create "settings" in the custom_settings file, used by the WebUI for version information and script updates ###
### local is the version of the script installed, server is the version on Github ###
Set_Version_Custom_Settings(){
	SETTINGSFILE=/jffs/addons/custom_settings.txt
	case "$1" in
		local)
			if [ -f "$SETTINGSFILE" ]; then
				if [ "$(grep -c "dnvnstat_version_local" $SETTINGSFILE)" -gt 0 ]; then
					if [ "$SCRIPT_VERSION" != "$(grep "dnvnstat_version_local" /jffs/addons/custom_settings.txt | cut -f2 -d' ')" ]; then
						sed -i "s/dnvnstat_version_local.*/dnvnstat_version_local $SCRIPT_VERSION/" "$SETTINGSFILE"
					fi
				else
					echo "dnvnstat_version_local $SCRIPT_VERSION" >> "$SETTINGSFILE"
				fi
			else
				echo "dnvnstat_version_local $SCRIPT_VERSION" >> "$SETTINGSFILE"
			fi
		;;
		server)
			if [ -f "$SETTINGSFILE" ]; then
				if [ "$(grep -c "dnvnstat_version_server" $SETTINGSFILE)" -gt 0 ]; then
					if [ "$2" != "$(grep "dnvnstat_version_server" /jffs/addons/custom_settings.txt | cut -f2 -d' ')" ]; then
						sed -i "s/dnvnstat_version_server.*/dnvnstat_version_server $2/" "$SETTINGSFILE"
					fi
				else
					echo "dnvnstat_version_server $2" >> "$SETTINGSFILE"
				fi
			else
				echo "dnvnstat_version_server $2" >> "$SETTINGSFILE"
			fi
		;;
	esac
}

### Checks for changes to Github version of script and returns reason for change (version or md5/minor), local version and server version ###
Update_Check(){
	echo 'var updatestatus = "InProgress";' > "$SCRIPT_WEB_DIR/detect_update.js"
	doupdate="false"
	localver=$(grep "SCRIPT_VERSION=" /jffs/scripts/"$SCRIPT_NAME" | grep -m1 -oE 'v[0-9]{1,2}([.][0-9]{1,2})([.][0-9]{1,2})')
	/usr/sbin/curl -fsL --retry 3 "$SCRIPT_REPO/$SCRIPT_NAME.sh" | grep -qF "de-vnull" || { Print_Output true "404 error detected - stopping update" "$ERR"; return 1; }
	serverver=$(/usr/sbin/curl -fsL --retry 3 "$SCRIPT_REPO/$SCRIPT_NAME.sh" | grep "SCRIPT_VERSION=" | grep -m1 -oE 'v[0-9]{1,2}([.][0-9]{1,2})([.][0-9]{1,2})')
	if [ "$localver" != "$serverver" ]; then
		doupdate="version"
		Set_Version_Custom_Settings server "$serverver"
		echo 'var updatestatus = "'"$serverver"'";'  > "$SCRIPT_WEB_DIR/detect_update.js"
	else
		localmd5="$(md5sum "/jffs/scripts/$SCRIPT_NAME" | awk '{print $1}')"
		remotemd5="$(curl -fsL --retry 3 "$SCRIPT_REPO/$SCRIPT_NAME.sh" | md5sum | awk '{print $1}')"
		if [ "$localmd5" != "$remotemd5" ]; then
			doupdate="md5"
			Set_Version_Custom_Settings "server" "$serverver-hotfix"
			echo 'var updatestatus = "'"$serverver-hotfix"'";'  > "$SCRIPT_WEB_DIR/detect_update.js"
		fi
	fi
	if [ "$doupdate" = "false" ]; then
		echo 'var updatestatus = "None";' > "$SCRIPT_WEB_DIR/detect_update.js"
	fi
	echo "$doupdate,$localver,$serverver"
}

### Updates the script from Github including any secondary files ###
### Accepts arguments of:
### force - download from server even if no change detected
### unattended - don't return user to script CLI menu
Update_Version(){
	if [ -z "$1" ] || [ "$1" = "unattended" ]; then
		updatecheckresult="$(Update_Check)"
		isupdate="$(echo "$updatecheckresult" | cut -f1 -d',')"
		localver="$(echo "$updatecheckresult" | cut -f2 -d',')"
		serverver="$(echo "$updatecheckresult" | cut -f3 -d',')"
		
		if [ "$isupdate" = "version" ]; then
			Print_Output true "New version of $SCRIPT_NAME available - updating to $serverver" "$PASS"
		elif [ "$isupdate" = "md5" ]; then
			Print_Output true "MD5 hash of $SCRIPT_NAME does not match - downloading updated $serverver" "$PASS"
		fi
		
		Update_File shared-jy.tar.gz
		
		if [ "$isupdate" != "false" ]; then
			Update_File vnstat-ui.asp
			Update_File vnstat.conf
			Update_File S33vnstat
			/usr/sbin/curl -fsL --retry 3 "$SCRIPT_REPO/$SCRIPT_NAME.sh" -o "/jffs/scripts/$SCRIPT_NAME" && Print_Output true "$SCRIPT_NAME successfully updated"
			chmod 0755 /jffs/scripts/"$SCRIPT_NAME"
			Clear_Lock
			if [ -z "$1" ]; then
				exec "$0" setversion
			elif [ "$1" = "unattended" ]; then
				exec "$0" setversion unattended
			fi
			exit 0
		else
			Print_Output true "No new version - latest is $localver" "$WARN"
			Clear_Lock
		fi
	fi
	
	if [ "$1" = "force" ]; then
		serverver=$(/usr/sbin/curl -fsL --retry 3 "$SCRIPT_REPO/$SCRIPT_NAME.sh" | grep "SCRIPT_VERSION=" | grep -m1 -oE 'v[0-9]{1,2}([.][0-9]{1,2})([.][0-9]{1,2})')
		Print_Output true "Downloading latest version ($serverver) of $SCRIPT_NAME" "$PASS"
		Update_File vnstat-ui.asp
		Update_File vnstat.conf
		Update_File S33vnstat
		Update_File shared-jy.tar.gz
		
		/usr/sbin/curl -fsL --retry 3 "$SCRIPT_REPO/$SCRIPT_NAME.sh" -o "/jffs/scripts/$SCRIPT_NAME" && Print_Output true "$SCRIPT_NAME successfully updated"
		chmod 0755 /jffs/scripts/"$SCRIPT_NAME"
		Clear_Lock
		if [ -z "$2" ]; then
			exec "$0" setversion
		elif [ "$2" = "unattended" ]; then
			exec "$0" setversion unattended
		fi
		exit 0
	fi
}

### Perform relevant actions for secondary files when being updated ###
Update_File(){
	if [ "$1" = "vnstat-ui.asp" ]; then ### WebUI page
		tmpfile="/tmp/$1"
		Download_File "$SCRIPT_REPO/$1" "$tmpfile"
		if ! diff -q "$tmpfile" "$SCRIPT_DIR/$1" >/dev/null 2>&1; then
			if [ -f "$SCRIPT_DIR/$1" ]; then
				Get_WebUI_Page "$SCRIPT_DIR/$1"
				sed -i "\\~$MyPage~d" /tmp/menuTree.js
				rm -f "$SCRIPT_WEBPAGE_DIR/$MyPage" 2>/dev/null
			fi
			Download_File "$SCRIPT_REPO/$1" "$SCRIPT_DIR/$1"
			Print_Output true "New version of $1 downloaded" "$PASS"
			Mount_WebUI
		fi
		rm -f "$tmpfile"
	elif [ "$1" = "shared-jy.tar.gz" ]; then ### shared web resources
		if [ ! -f "$SHARED_DIR/$1.md5" ]; then
			Download_File "$SHARED_REPO/$1" "$SHARED_DIR/$1"
			Download_File "$SHARED_REPO/$1.md5" "$SHARED_DIR/$1.md5"
			tar -xzf "$SHARED_DIR/$1" -C "$SHARED_DIR"
			rm -f "$SHARED_DIR/$1"
			Print_Output true "New version of $1 downloaded" "$PASS"
		else
			localmd5="$(cat "$SHARED_DIR/$1.md5")"
			remotemd5="$(curl -fsL --retry 3 "$SHARED_REPO/$1.md5")"
			if [ "$localmd5" != "$remotemd5" ]; then
				Download_File "$SHARED_REPO/$1" "$SHARED_DIR/$1"
				Download_File "$SHARED_REPO/$1.md5" "$SHARED_DIR/$1.md5"
				tar -xzf "$SHARED_DIR/$1" -C "$SHARED_DIR"
				rm -f "$SHARED_DIR/$1"
				Print_Output true "New version of $1 downloaded" "$PASS"
			fi
		fi
	elif [ "$1" = "S33vnstat" ]; then ### Entware S script to launch vnstat
		tmpfile="/tmp/$1"
		Download_File "$SCRIPT_REPO/$1" "$tmpfile"
		if ! diff -q "$tmpfile" "/opt/etc/init.d/$1" >/dev/null 2>&1; then
			if [ -f /opt/etc/init.d/S33vnstat ]; then
				/opt/etc/init.d/S33vnstat stop >/dev/null 2>&1
				sleep 2
			fi
			Download_File "$SCRIPT_REPO/$1" "/opt/etc/init.d/$1"
			chmod 0755 "/opt/etc/init.d/$1"
			/opt/etc/init.d/S33vnstat start >/dev/null 2>&1
			Print_Output true "New version of $1 downloaded" "$PASS"
		fi
		rm -f "$tmpfile"
	elif [ "$1" = "vnstat.conf" ]; then ### vnstat config file
		tmpfile="/tmp/$1"
		Download_File "$SCRIPT_REPO/$1" "$tmpfile"
		if [ ! -f "$SCRIPT_DIR/$1" ]; then
			Download_File "$SCRIPT_REPO/$1" "$SCRIPT_DIR/$1.default"
			Download_File "$SCRIPT_REPO/$1" "$SCRIPT_DIR/$1"
			Print_Output true "$SCRIPT_DIR/$1 does not exist, downloading now." "$PASS"
		elif [ -f "$SCRIPT_DIR/$1.default" ]; then
			if ! diff -q "$tmpfile" "$SCRIPT_DIR/$1.default" >/dev/null 2>&1; then
				Download_File "$SCRIPT_REPO/$1" "$SCRIPT_DIR/$1.default"
				Print_Output true "New default version of $1 downloaded to $SCRIPT_DIR/$1.default, please compare against your $SCRIPT_DIR/$1" "$PASS"
			fi
		else
			Download_File "$SCRIPT_REPO/$1" "$SCRIPT_DIR/$1.default"
			Print_Output true "$SCRIPT_DIR/$1.default does not exist, downloading now. Please compare against your $SCRIPT_DIR/$1" "$PASS"
		fi
		rm -f "$tmpfile"
	else
		return 1
	fi
}

### Create directories in filesystem if they do not exist ###
Create_Dirs(){
	if [ ! -d "$SCRIPT_DIR" ]; then
		mkdir -p "$SCRIPT_DIR"
	fi
	
	if [ ! -d "$IMAGE_OUTPUT_DIR" ]; then
		mkdir -p "$IMAGE_OUTPUT_DIR"
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

### Create symbolic links to /www/user for WebUI files to avoid file duplication ###
Create_Symlinks(){
	rm -rf "${SCRIPT_WEB_DIR:?}/"* 2>/dev/null
	
	ln -s /tmp/detect_vnstat.js "$SCRIPT_WEB_DIR/detect_vnstat.js" 2>/dev/null
	
	ln -s "$IMAGE_OUTPUT_DIR" "$SCRIPT_WEB_DIR/images" 2>/dev/null
	
	if [ ! -d "$SHARED_WEB_DIR" ]; then
		ln -s "$SHARED_DIR" "$SHARED_WEB_DIR" 2>/dev/null
	fi
}

### Add script hook to service-event and pass service_event argument and all other arguments passed to the service call ###
Auto_ServiceEvent(){
	case $1 in
		create)
			if [ -f /jffs/scripts/service-event ]; then
				STARTUPLINECOUNT=$(grep -c '# '"$SCRIPT_NAME" /jffs/scripts/service-event)
				# shellcheck disable=SC2016
				STARTUPLINECOUNTEX=$(grep -cx "/jffs/scripts/$SCRIPT_NAME service_event"' "$@" & # '"$SCRIPT_NAME" /jffs/scripts/service-event)
				
				if [ "$STARTUPLINECOUNT" -gt 1 ] || { [ "$STARTUPLINECOUNTEX" -eq 0 ] && [ "$STARTUPLINECOUNT" -gt 0 ]; }; then
					sed -i -e '/# '"$SCRIPT_NAME"'/d' /jffs/scripts/service-event
				fi
				
				if [ "$STARTUPLINECOUNTEX" -eq 0 ]; then
					# shellcheck disable=SC2016
					echo "/jffs/scripts/$SCRIPT_NAME service_event"' "$@" & # '"$SCRIPT_NAME" >> /jffs/scripts/service-event
				fi
			else
				echo "#!/bin/sh" > /jffs/scripts/service-event
				echo "" >> /jffs/scripts/service-event
				# shellcheck disable=SC2016
				echo "/jffs/scripts/$SCRIPT_NAME service_event"' "$@" & # '"$SCRIPT_NAME" >> /jffs/scripts/service-event
				chmod 0755 /jffs/scripts/service-event
			fi
		;;
		delete)
			if [ -f /jffs/scripts/service-event ]; then
				STARTUPLINECOUNT=$(grep -c '# '"$SCRIPT_NAME" /jffs/scripts/service-event)
				
				if [ "$STARTUPLINECOUNT" -gt 0 ]; then
					sed -i -e '/# '"$SCRIPT_NAME"'/d' /jffs/scripts/service-event
				fi
			fi
		;;
	esac
}

### Add script hook to post-mount and pass startup argument and all other arguments passed with the partition mount ###
Auto_Startup(){
	case $1 in
		create)
			if [ -f /jffs/scripts/post-mount ]; then
				STARTUPLINECOUNT=$(grep -c '# '"$SCRIPT_NAME" /jffs/scripts/post-mount)
				STARTUPLINECOUNTEX=$(grep -cx "/jffs/scripts/$SCRIPT_NAME startup"' "$@" & # '"$SCRIPT_NAME" /jffs/scripts/post-mount)
				
				if [ "$STARTUPLINECOUNT" -gt 1 ] || { [ "$STARTUPLINECOUNTEX" -eq 0 ] && [ "$STARTUPLINECOUNT" -gt 0 ]; }; then
					sed -i -e '/# '"$SCRIPT_NAME"'/d' /jffs/scripts/post-mount
				fi
				
				if [ "$STARTUPLINECOUNTEX" -eq 0 ]; then
					echo "/jffs/scripts/$SCRIPT_NAME startup"' "$@" & # '"$SCRIPT_NAME" >> /jffs/scripts/post-mount
				fi
			else
				echo "#!/bin/sh" > /jffs/scripts/post-mount
				echo "" >> /jffs/scripts/post-mount
				echo "/jffs/scripts/$SCRIPT_NAME startup"' "$@" & # '"$SCRIPT_NAME" >> /jffs/scripts/post-mount
				chmod 0755 /jffs/scripts/post-mount
			fi
		;;
		delete)
			if [ -f /jffs/scripts/post-mount ]; then
				STARTUPLINECOUNT=$(grep -c '# '"$SCRIPT_NAME" /jffs/scripts/post-mount)
				
				if [ "$STARTUPLINECOUNT" -gt 0 ]; then
					sed -i -e '/# '"$SCRIPT_NAME"'/d' /jffs/scripts/post-mount
				fi
			fi
		;;
	esac
}


Auto_Cron(){
	case $1 in
		create)
			STARTUPLINECOUNT=$(cru l | grep -c "${SCRIPT_NAME}_images")
			if [ "$STARTUPLINECOUNT" -eq 0 ]; then
				cru a "${SCRIPT_NAME}_images" "*/5 * * * * /jffs/scripts/$SCRIPT_NAME generateimages"
			fi
			
			STARTUPLINECOUNT=$(cru l | grep -c "${SCRIPT_NAME}_stats")
			if [ "$STARTUPLINECOUNT" -eq 0 ]; then
				cru a "${SCRIPT_NAME}_stats" "59 23 * * * /jffs/scripts/$SCRIPT_NAME generatestats"
			fi
		;;
		delete)
			STARTUPLINECOUNT=$(cru l | grep -c "${SCRIPT_NAME}_images")
			if [ "$STARTUPLINECOUNT" -gt 0 ]; then
				cru d "${SCRIPT_NAME}_images"
			fi
			
			STARTUPLINECOUNT=$(cru l | grep -c "${SCRIPT_NAME}_stats")
			if [ "$STARTUPLINECOUNT" -gt 0 ]; then
				cru d "${SCRIPT_NAME}_stats"
			fi
		;;
	esac
}

Download_File(){
	/usr/sbin/curl -fsL --retry 3 "$1" -o "$2"
}

Get_WebUI_Page(){
	MyPage="none"
	for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20; do
		page="/www/user/user$i.asp"
		if [ -f "$page" ] && [ "$(md5sum < "$1")" = "$(md5sum < "$page")" ]; then
			MyPage="user$i.asp"
			return
		elif [ "$MyPage" = "none" ] && [ ! -f "$page" ]; then
			MyPage="user$i.asp"
		fi
	done
}

### locking mechanism code credit to Martineau (@MartineauUK) ###
Mount_WebUI(){
	LOCKFILE=/tmp/addonwebui.lock
	FD=386
	eval exec "$FD>$LOCKFILE"
	flock -x "$FD"
	Get_WebUI_Page "$SCRIPT_DIR/vnstat-ui.asp"
	if [ "$MyPage" = "none" ]; then
		Print_Output true "Unable to mount $SCRIPT_NAME WebUI page, exiting" "$CRIT"
		flock -u "$FD"
		return 1
	fi
	cp -f "$SCRIPT_DIR/vnstat-ui.asp" "$SCRIPT_WEBPAGE_DIR/$MyPage"
	echo "dn-vnstat" > "$SCRIPT_WEBPAGE_DIR/$(echo $MyPage | cut -f1 -d'.').title"
	
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
		sed -i "/url: \"javascript:window.open('\/ext\/shared-jy\/redirect.htm'/i {url: \"$MyPage\", tabName: \"dn-vnstat\"}," /tmp/menuTree.js
		
		umount /www/require/modules/menuTree.js 2>/dev/null
		mount -o bind /tmp/menuTree.js /www/require/modules/menuTree.js
	fi
	flock -u "$FD"
	Print_Output true "Mounted $SCRIPT_NAME WebUI page as $MyPage" "$PASS"
}

Shortcut_Script(){
	case $1 in
		create)
			if [ -d /opt/bin ] && [ ! -f "/opt/bin/$SCRIPT_NAME" ] && [ -f "/jffs/scripts/$SCRIPT_NAME" ]; then
				ln -s /jffs/scripts/"$SCRIPT_NAME" /opt/bin
				chmod 0755 /opt/bin/"$SCRIPT_NAME"
			fi
		;;
		delete)
			if [ -f "/opt/bin/$SCRIPT_NAME" ]; then
				rm -f /opt/bin/"$SCRIPT_NAME"
			fi
		;;
	esac
}

PressEnter(){
	while true; do
		printf "Press enter to continue..."
		read -r key
		case "$key" in
			*)
				break
			;;
		esac
	done
	return 0
}

Check_Requirements(){
	CHECKSFAILED="false"

	if [ "$(nvram get jffs2_scripts)" -ne 1 ]; then
		nvram set jffs2_scripts=1
		nvram commit
		Print_Output true "Custom JFFS Scripts enabled" "$WARN"
	fi

	if [ ! -f /opt/bin/opkg ]; then
		Print_Output true "Entware not detected!" "$ERR"
		CHECKSFAILED="true"
	fi

	if ! Firmware_Version_Check; then
		Print_Output true "Unsupported firmware version detected" "$ERR"
		Print_Output true "$SCRIPT_NAME requires Merlin 384.15/384.13_4 or Fork 43E5 (or later)" "$ERR"
		CHECKSFAILED="true"
	fi

	if [ "$CHECKSFAILED" = "false" ]; then
		Print_Output true "Installing required packages from Entware" "$PASS"
		opkg update
		opkg install vnstat
		opkg install vnstati
		opkg install imagemagick
		rm -f /opt/etc/vnstat.conf
		return 0
	else
		return 1
	fi
}


### Determine WAN interface using nvram ###
Get_WAN_IFace(){
	if [ "$(nvram get wan0_proto)" = "pppoe" ] || [ "$(nvram get wan0_proto)" = "pptp" ] || [ "$(nvram get wan0_proto)" = "l2tp" ]; then
		IFACE_WAN="ppp0"
	else
		IFACE_WAN="$(nvram get wan0_ifname)"
	fi
	echo "$IFACE_WAN"
}

Generate_Images(){
	# Adapted from http://code.google.com/p/x-wrt/source/browse/trunk/package/webif/files/www/cgi-bin/webif/graphs-vnstat.sh
	Print_Output false "vnstati updating stats for UI" "$PASS"
	$VNSTAT_COMMAND -u
	
	outputs="s h d t m hs"   # what images to generate
	
	interface="$(grep "Interface " "$SCRIPT_DIR/vnstat.conf" | awk '{print $2}' | sed 's/"//g')"
	
	for output in $outputs; do
		$VNSTATI_COMMAND -"$output" -i "$interface" -o "$IMAGE_OUTPUT_DIR/vnstat_$output.png"
	done
}

Generate_Stats(){
	printf "vnstats as of:\\n%s" "$(date)" > /tmp/vnstat.txt
	$VNSTAT_COMMAND -u
	{
		$VNSTAT_COMMAND -m;
		$VNSTAT_COMMAND -w;
		$VNSTAT_COMMAND -d;
	} >> /tmp/vnstat.txt
	cat /tmp/vnstat.txt
	convert -font DejaVu-Sans-Mono -channel RGB -negate label:@- "$IMAGE_OUTPUT_DIR/vnstat.png" < /tmp/vnstat.txt
	printf "\\n"
	Print_Output true "vnstat_totals summary generated" "$PASS"
}

Generate_Email(){
	if [ -f "$ENABLE_EMAIL_FILE" ]; then
		if [ ! -f /opt/bin/diversion ]; then
			Print_Output true "$SCRIPT_NAME relies on Diversion to send email summaries, and Diversion is not installed" "$ERR"
			Print_Output true "Diversion can be installed using amtm" "$ERR"
			return 1
		elif [ ! -f /opt/share/diversion/.conf/emailpw.enc ] || [ ! -f /opt/share/diversion/.conf/email.conf ]; then
			Print_Output true "$SCRIPT_NAME relies on Diversion to send email summaries, and email settings have not been configured" "$ERR"
			Print_Output true "Navigate to amtm > 1 (Diversion) > c (communication) > 5 (edit email settings, test email) to set this up" "$ERR"
			return 1
		else
			Print_Output true "Attempting to send summary statistic email"
			# Adapted from elorimer snbforum's script leveraging Diversion email credentials - agreed by thelonelycoder as well
			# This script is used to email the daily/weekly/monthly vnstat usage for the Vnstat on Merlin script and UI - by dev_null at snbforums
			
			# Email settings #
			. /opt/share/diversion/.conf/email.conf
			PWENCFILE=/opt/share/diversion/.conf/emailpw.enc
			PASSWORD=""
			# shellcheck disable=SC2154
			if /usr/sbin/openssl aes-256-cbc -d -in "$PWENCFILE" -pass pass:ditbabot,isoi >/dev/null 2>&1 ; then
				# old OpenSSL 1.0.x
				PASSWORD="$(/usr/sbin/openssl aes-256-cbc -d -in "$PWENCFILE" -pass pass:ditbabot,isoi 2>/dev/null)"
			elif /usr/sbin/openssl aes-256-cbc -d -md md5 -in "$PWENCFILE" -pass pass:ditbabot,isoi >/dev/null 2>&1 ; then
				# new OpenSSL 1.1.x non-converted password
				PASSWORD="$(/usr/sbin/openssl aes-256-cbc -d -md md5 -in "$PWENCFILE" -pass pass:ditbabot,isoi 2>/dev/null)"
			elif /usr/sbin/openssl aes-256-cbc $emailPwEnc -d -in "$PWENCFILE" -pass pass:ditbabot,isoi >/dev/null 2>&1 ; then
				# new OpenSSL 1.1.x converted password with -pbkdf2 flag
				PASSWORD="$(/usr/sbin/openssl aes-256-cbc $emailPwEnc -d -in "$PWENCFILE" -pass pass:ditbabot,isoi 2>/dev/null)"
			fi
			
			if grep -q TEXT "$ENABLE_EMAIL_FILE";  then
				# plain text email to send #
				{
					echo "From: \"$FRIENDLY_ROUTER_NAME\" <$FROM_ADDRESS>";
					echo "To: \"$TO_NAME\" <$TO_ADDRESS>";
					echo "Subject: vnstat-stats as of $(date +"%H.%M on %F")";
					echo "Date: $(date -R)";
					echo "";
				} > /tmp/mail.txt
				cat /tmp/vnstat.txt >>/tmp/mail.txt
			elif grep -q HTML "$ENABLE_EMAIL_FILE"; then
				# html message to send #
				{
					echo "From: \"$FRIENDLY_ROUTER_NAME\" <$FROM_ADDRESS>";
					echo "To: \"$TO_NAME\" <$TO_ADDRESS>";
					echo "Subject: vnstat-stats as of $(date +"%H.%M on %F")";
					echo "Date: $(date -R)";
					echo "MIME-Version: 1.0";
					echo "Content-Type: multipart/mixed; boundary=\"MULTIPART-MIXED-BOUNDARY\"";
					echo "hello there";
					echo "";
					echo "--MULTIPART-MIXED-BOUNDARY";
					echo "Content-Type: multipart/related; boundary=\"MULTIPART-RELATED-BOUNDARY\"";
					echo "";
					echo "--MULTIPART-RELATED-BOUNDARY";
					echo "Content-Type: multipart/alternative; boundary=\"MULTIPART-ALTERNATIVE-BOUNDARY\"";
				} > /tmp/mail.txt
				
				outputs="s h d t m hs"
				echo "<html><body><p>Welcome to your dn-vnstat stats email!</p>" > /tmp/message.html
				for output in $outputs; do
					echo "<p><img src=\"cid:vnstat_$output.png\"></p>" >> /tmp/message.html
				done
				echo "</body></html>" >> /tmp/message.html
				message_base64="$(openssl base64 -A < /tmp/message.html)"
				rm -f /tmp/message.html
				{
					echo "";
					echo "--MULTIPART-ALTERNATIVE-BOUNDARY";
					echo "Content-Type: text/html; charset=utf-8";
					echo "Content-Transfer-Encoding: base64";
					echo "";
					echo "$message_base64";
					echo "";
					echo "--MULTIPART-ALTERNATIVE-BOUNDARY--";
					echo "";
				} >> /tmp/mail.txt
				
				for output in $outputs; do
					image_base64="$(openssl base64 -A < "$IMAGE_OUTPUT_DIR/vnstat_$output.png")"
					Encode_Image "vnstat_$output.png" "$image_base64" /tmp/mail.txt
				done
				
				Encode_Text vnstat.txt "$(cat /tmp/vnstat.txt)" /tmp/mail.txt
				
				{
					echo "--MULTIPART-RELATED-BOUNDARY--";
					echo "";
					echo "--MULTIPART-MIXED-BOUNDARY--";
				} >> /tmp/mail.txt
			fi
			
			#Send Email
			/usr/sbin/curl -s --show-error --url "$PROTOCOL://$SMTP:$PORT" \
			--mail-from "$FROM_ADDRESS" --mail-rcpt "$TO_ADDRESS" \
			--upload-file /tmp/mail.txt \
			--ssl-reqd \
			--user "$USERNAME:$PASSWORD" $SSL_FLAG
			# shellcheck disable=SC2181
			if [ $? -eq 0 ]; then
				Print_Output true "Summary statistic email sent" "$PASS"
				rm -f /tmp/mail.txt
				return 0
			else
				echo ""
				Print_Output true "Summary statistic email failed to send" "$ERR"
				rm -f /tmp/mail.txt
				return 1
			fi
		fi
	fi
}

# encode image for email inline
# $1 : image content id filename (match the cid:filename.png in html document)
# $2 : image content base64 encoded
# $3 : output file
Encode_Image(){
	{
		echo "";
		echo "--MULTIPART-RELATED-BOUNDARY";
		echo "Content-Type: image/png;name=\"$1\"";
		echo "Content-Transfer-Encoding: base64";
		echo "Content-Disposition: inline;filename=\"$1\"";
		echo "Content-Id: <$1>";
		echo "";
		echo "$2";
	} >> "$3"
}

# encode text for email inline
# $1 : text content base64 encoded
# $2 : output file
Encode_Text(){
	{
		echo "";
		echo "--MULTIPART-RELATED-BOUNDARY";
		echo "Content-Type: text/plain;name=\"$1\"";
		echo "Content-Transfer-Encoding: quoted-printable";
		echo "Content-Disposition: attachment;filename=\"$1\"";
		echo "";
		echo "$2";
	} >> "$3"
}

ToggleEmail(){
	case "$1" in
		enable)
			if [ -z "$2" ]; then
				ScriptHeader
				exitmenu="false"
				printf "\\n\\e[1mA choice of emails is available:\\e[0m\\n"
				printf "1.    Plain text (summary stats only)\\n"
				printf "2.    HTML (beta - includes images from WebUI + summary stats as attachment)\\n"
				printf "\\ne.    Exit to main menu\\n"
				
				while true; do
					printf "\\n\\e[1mChoose an option:\\e[0m    "
					read -r emailtype
					case "$emailtype" in
						1)
							echo "TEXT" > "$ENABLE_EMAIL_FILE"
							break
						;;
						2)
							echo "HTML" > "$ENABLE_EMAIL_FILE"
							break
						;;
						e)
							exitmenu="true"
							break
						;;
						*)
							printf "\\nPlease choose a valid option\\n\\n"
						;;
					esac
				done
				
				printf "\\n"
				
				if [ "$exitmenu" = "true" ]; then
					return
				fi
			fi
			
			Generate_Email
			if [ "$?" -eq 1 ]; then
				ToggleEmail disable
			fi
		;;
		disable)
			rm -f "$ENABLE_EMAIL_FILE"
		;;
		check)
			if [ -f "$ENABLE_EMAIL_FILE" ]; then
				if grep -q HTML "$ENABLE_EMAIL_FILE"; then
					echo "ENABLED - HTML"
				elif grep -q TEXT "$ENABLE_EMAIL_FILE";  then
					echo "ENABLED - TEXT"
				fi
			else
				echo "DISABLED"
			fi
		;;
	esac
}

vom_rio(){
	ScriptHeader
	printf "\\n\\nPrevious alpha/beta1/self-install version of Vnstat on Merlin has been detected on your router.\\n"
	printf "\\n\\e[1m%s needs to remove this version to install a newer version.\\e[0m\\n" "$SCRIPT_NAME"
	printf "\\nNote that %s will NOT delete any existing vnstat database files.\\n" "$SCRIPT_NAME"
	printf "\\n\\e[33mPress y to continue or any other key to quit this installation and keep the existing version:\\e[0m  "
	read -r CONDITION
	
	if [ "$CONDITION" = "y" ]; then
		Print_Output false "Uninstalling 'VoM alpha/beta1/manual version'..."
		# Kill vnstat - probably not necessary, but better safe
		Print_Output false "Stopping vnstatd..."
		/opt/etc/init.d/S32vnstat stop
		killall vnstatd 2>/dev/null
		
		# Delete cron jobs
		Print_Output false "Removing cron jobs..."
		cru d vnstat_daily
		cru d vnstat_update
		# Delete vnstat activities from the various startup scripts
		Print_Output false "Removing vnstat hooks from user scripts..."
		grep "vnstat_daily" /jffs/scripts/service-event && sed -i '/vnstat_daily/d' /jffs/scripts/service-event 2>/dev/null
		grep "vnstat_update" /jffs/scripts/service-event && sed -i '/vnstat_update/d' /jffs/scripts/service-event 2>/dev/null
		grep "vnstat_daily" /jffs/scripts/services-start && sed -i '/vnstat_daily/d' /jffs/scripts/services-start 2>/dev/null
		grep "vnstat_update" /jffs/scripts/services-start && sed -i '/vnstat_update/d' /jffs/scripts/services-start 2>/dev/null
		grep "vnstat-ui" /jffs/scripts/post-mount && sed -i '/vnstat-ui/d' /jffs/scripts/post-mount 2>/dev/null
		# Now remove the directories and files associated with the alpha/beta1/manual installations
		Print_Output false "Deleting directories '/jffs/addons/vnstat*' and other un-needed files - no database files will be removed."
		Get_WebUI_Page "/jffs/addons/vnstat-ui.d/vnstat-ui.asp"
		if [ -n "$MyPage" ] && [ "$MyPage" != "none" ] && [ -f "/tmp/menuTree.js" ]; then
			sed -i "\\~$MyPage~d" /tmp/menuTree.js
			umount /www/require/modules/menuTree.js
			mount -o bind /tmp/menuTree.js /www/require/modules/menuTree.js
		fi
		rm -rf /jffs/addons/vnstat-ui.d
		rm -rf /jffs/addons/vnstat.d
		rm -f /jffs/scripts/send-vnstat.sh
		rm -f /jffs/scripts/vnstat-stats
		rm -f /jffs/scripts/vnstat-ui
		rm -f /jffs/scripts/vnstat-ww.sh
		rm -f /jffs/scripts/vnstat-install.sh
		Print_Output false "Renaming /opt/etc/vnstat.conf to /opt/etc/vnstat.conf.old"
		mv /opt/etc/vnstat.conf /opt/etc/vnstat.conf.old
		# Wrap up
		Print_Output false "Removal of old script files completed. Installation of $SCRIPT_NAME will continue." "$PASS"
		printf "\\n\\e[1m\\e[33mNote, if you made any manual edits to /opt/etc/vnstat.conf (such as customizing the location of the database files)\\n"
		printf "you will need to re-apply them to %s/vnstat.conf once installation is complete.\\e[0m\\n" "$SCRIPT_DIR"
		PressEnter
		ScriptHeader
	else
		Print_Output false "Exiting, previous version of vnstat script must be removed to install $SCRIPT_NAME"
		PressEnter
		Clear_Lock
		rm -f "/jffs/scripts/$SCRIPT_NAME" 2>/dev/null
		exit 1
	fi
}

ScriptHeader(){
	clear
	printf "\\n"
	printf "\\e[1m#################################################\\e[0m\\n"
	printf "\\e[1m##                                             ##\\e[0m\\n"
	printf "\\e[1m##  vnstat and vnstati data usage statistics   ##\\e[0m\\n"
	printf "\\e[1m##              for AsusWRT-Merlin             ##\\e[0m\\n"
	printf "\\e[1m##                                             ##\\e[0m\\n"
	printf "\\e[1m##              %s on %-9s            ##\\e[0m\\n" "$SCRIPT_VERSION" "$ROUTER_MODEL"
	printf "\\e[1m##                                             ## \\e[0m\\n"
	printf "\\e[1m##            Created by dev_null              ##\\e[0m\\n"
	printf "\\e[1m##                                             ##\\e[0m\\n"
	printf "\\e[1m#################################################\\e[0m\\n"
	printf "\\n"
}

MainMenu(){
	printf "1.    Update stats now\\n\\n"
	printf "2.    Toggle emails for daily summary stats\\n      Currently: \\e[1m%s\\e[0m\\n\\n" "$(ToggleEmail check)"
	printf "3.    Edit %s config\\n\\n" "$SCRIPT_NAME"
	printf "u.    Check for updates\\n"
	printf "uf.   Force update %s with latest version\\n\\n" "$SCRIPT_NAME"
	printf "e.    Exit %s\\n\\n" "$SCRIPT_NAME"
	printf "z.    Uninstall %s\\n" "$SCRIPT_NAME"
	printf "\\n"
	printf "\\e[1m#################################################\\e[0m\\n"
	printf "\\n"
	
	while true; do
		printf "Choose an option:    "
		read -r menu
		case "$menu" in
			1)
				printf "\\n"
				if Check_Lock menu; then
					Menu_GenerateStats
				fi
				PressEnter
				break
			;;
			2)
				printf "\\n"
				Menu_ToggleEmail
				PressEnter
				break
			;;
			3)
				printf "\\n"
				if Check_Lock menu; then
					Menu_Edit
				fi
				break
			;;
			u)
				printf "\\n"
				if Check_Lock menu; then
					Menu_Update
				fi
				PressEnter
				break
			;;
			uf)
				printf "\\n"
				if Check_Lock menu; then
					Menu_ForceUpdate
				fi
				PressEnter
				break
			;;
			e)
				ScriptHeader
				printf "\\n\\e[1mThanks for using %s!\\e[0m\\n\\n\\n" "$SCRIPT_NAME"
				exit 0
			;;
			z)
				while true; do
					printf "\\n\\e[1mAre you sure you want to uninstall %s? (y/n)\\e[0m\\n" "$SCRIPT_NAME"
					read -r confirm
					case "$confirm" in
						y|Y)
							Menu_Uninstall
							exit 0
						;;
						*)
							break
						;;
					esac
				done
			;;
			*)
				printf "\\nPlease choose a valid option\\n\\n"
			;;
		esac
	done
	
	ScriptHeader
	MainMenu
}

Menu_Install(){
	Print_Output true "Welcome to $SCRIPT_NAME $SCRIPT_VERSION, a script by dev_null"
	sleep 1
	
	if [ -d /jffs/addons/vnstat.d ] || [ -f /opt/etc/vnstat.conf ] || [ -f /jffs/scripts/vnstat-install.sh ]; then
		vom_rio
	fi
	
	Print_Output true "Checking your router meets the requirements for $SCRIPT_NAME"
	
	if ! Check_Requirements; then
		Print_Output true "Requirements for $SCRIPT_NAME not met, please see above for the reason(s)" "$CRIT"
		PressEnter
		Clear_Lock
		rm -f "/jffs/scripts/$SCRIPT_NAME" 2>/dev/null
		exit 1
	fi
	
	IFACE=""
	printf "\\n\\e[1mWAN Interface detected as %s\\e[0m\\n" "$(Get_WAN_IFace)"
	while true; do
		printf "\\n\\e[1mIs this correct? (y/n)\\e[0m    "
		read -r confirm
		case "$confirm" in
			y|Y)
				IFACE="$(Get_WAN_IFace)"
				break
			;;
			n|N)
				while true; do
					printf "\\n\\e[1mPlease enter correct interface:\\e[0m    "
					read -r iface
					iface_lower="$(echo "$iface" | tr "A-Z" "a-z")"
					if [ "$iface" = "e" ]; then
						Clear_Lock
						rm -f "/jffs/scripts/$SCRIPT_NAME" 2>/dev/null
						exit 1
					elif [ ! -f "/sys/class/net/$iface_lower/operstate" ] || [ "$(cat "/sys/class/net/$iface_lower/operstate")" = "down" ]; then
						printf "\\n\\e[31mInput is not a valid interface or interface not up, please try again\\e[0m\\n"
					else
						IFACE="$iface_lower"
						break
					fi
				done
			;;
			*)
				:
			;;
		esac
	done
	
	printf "\\n"
	
	Create_Dirs
	Set_Version_Custom_Settings local
	Set_Version_Custom_Settings server "$SCRIPT_VERSION"
	Create_Symlinks
	
	Update_File vnstat.conf
	sed -i 's/^Interface .*$/Interface "'"$IFACE"'"/' "$SCRIPT_DIR/vnstat.conf"
	
	Update_File vnstat-ui.asp
	Update_File S33vnstat
	Update_File shared-jy.tar.gz
	
	Auto_Startup create 2>/dev/null
	Auto_Cron create 2>/dev/null
	Auto_ServiceEvent create 2>/dev/null
	Shortcut_Script create
	
	if [ -n "$(pidof vnstatd)" ];then
		Print_Output true "Sleeping for 5s before generating initial stats" "$WARN"
		sleep 5
		Generate_Stats
		Generate_Images
	else
		Print_Output true "vnstatd not running, please check system log" "$ERR"
	fi
	
	Clear_Lock
	ScriptHeader
	MainMenu
}

Menu_Startup(){
	if [ -z "$1" ]; then
		Print_Output true "Missing argument for startup, not starting $SCRIPT_NAME" "$WARN"
		exit 1
	elif [ "$1" != "force" ]; then
		if [ ! -f "$1/entware/bin/opkg" ]; then
			Print_Output true "$1 does not contain Entware, not starting $SCRIPT_NAME" "$WARN"
			exit 1
		else
			Print_Output true "$1 contains Entware, starting $SCRIPT_NAME" "$WARN"
		fi
	fi
	
	NTP_Ready
	
	Check_Lock
	
	if [ "$1" != "force" ]; then
		sleep 5
	fi
	Create_Dirs
	Set_Version_Custom_Settings local
	Create_Symlinks
	Auto_Startup create 2>/dev/null
	Auto_Cron create 2>/dev/null
	Auto_ServiceEvent create 2>/dev/null
	Shortcut_Script create
	Mount_WebUI
	Clear_Lock
}

Menu_GenerateStats(){
	Generate_Images
	Generate_Stats
	Clear_Lock
}

Menu_ToggleEmail(){
	if [ -z "$1" ]; then
		if [ -f "$ENABLE_EMAIL_FILE" ]; then
			ToggleEmail disable
		elif [ ! -f "$ENABLE_EMAIL_FILE" ]; then
			ToggleEmail enable
		fi
	else
		ToggleEmail "$@"
	fi
}

Menu_Edit(){
	texteditor=""
	exitmenu="false"
	
	printf "\\n\\e[1mA choice of text editors is available:\\e[0m\\n"
	printf "1.    nano (recommended for beginners)\\n"
	printf "2.    vi\\n"
	printf "\\ne.    Exit to main menu\\n"
	
	while true; do
		printf "\\n\\e[1mChoose an option:\\e[0m    "
		read -r editor
		case "$editor" in
			1)
				texteditor="nano -K"
				break
			;;
			2)
				texteditor="vi"
				break
			;;
			e)
				exitmenu="true"
				break
			;;
			*)
				printf "\\nPlease choose a valid option\\n\\n"
			;;
		esac
	done
	
	if [ "$exitmenu" != "true" ]; then
		CONFFILE="$SCRIPT_DIR/vnstat.conf"
		oldmd5="$(md5sum "$CONFFILE" | awk '{print $1}')"
		$texteditor "$CONFFILE"
		newmd5="$(md5sum "$CONFFILE" | awk '{print $1}')"
		if [ "$oldmd5" != "$newmd5" ]; then
			/opt/etc/init.d/S33vnstat restart >/dev/null 2>&1
		fi
	fi
	Clear_Lock
}

Menu_Update(){
	Update_Version
	Clear_Lock
}

Menu_ForceUpdate(){
	Update_Version force
	Clear_Lock
}

Menu_Uninstall(){
	Print_Output true "Removing $SCRIPT_NAME..." "$PASS"
	Auto_Startup delete 2>/dev/null
	Auto_Cron delete 2>/dev/null
	Auto_ServiceEvent delete 2>/dev/null
	
	Get_WebUI_Page "$SCRIPT_DIR/vnstat-ui.asp"
	if [ -n "$MyPage" ] && [ "$MyPage" != "none" ] && [ -f "/tmp/menuTree.js" ]; then
		sed -i "\\~$MyPage~d" /tmp/menuTree.js
		umount /www/require/modules/menuTree.js
		mount -o bind /tmp/menuTree.js /www/require/modules/menuTree.js
		rm -rf "{$SCRIPT_WEBPAGE_DIR:?}/$MyPage"
	fi
	rm -f "$SCRIPT_DIR/vnstat-ui.asp"
	rm -rf "$SCRIPT_WEB_DIR"
	
	Shortcut_Script delete
	/opt/etc/init.d/S33vnstat stop >/dev/null 2>&1
	touch /opt/etc/vnstat.conf
	opkg remove --autoremove vnstati
	opkg remove --autoremove vnstat
	opkg remove --autoremove imagemagick
	
	rm -f /opt/etc/init.d/S33vnstat
	rm -f /opt/etc/vnstat.conf
	
	SETTINGSFILE=/jffs/addons/custom_settings.txt
	sed -i '/dnvnstat_version_local/d' "$SETTINGSFILE"
	sed -i '/dnvnstat_version_server/d' "$SETTINGSFILE"
	
	printf "\\n\\e[1mWould you like to keep the vnstat data files? (y/n)\\e[0m\\n"
	read -r confirm
	case "$confirm" in
		y|Y)
			:
		;;
		*)
			rm -rf "$SCRIPT_DIR"
			rm -rf /opt/var/lib/vnstat
			rm -f /opt/etc/vnstat.conf
		;;
	esac
	
	rm -f "/jffs/scripts/$SCRIPT_NAME"
	Clear_Lock
	Print_Output true "Uninstall completed" "$PASS"
}

NTP_Ready(){
	if [ "$(nvram get ntp_ready)" -eq 0 ]; then
		Check_Lock
		ntpwaitcount="0"
		while [ "$(nvram get ntp_ready)" -eq 0 ] && [ "$ntpwaitcount" -lt 300 ]; do
			ntpwaitcount="$((ntpwaitcount + 1))"
			if [ "$ntpwaitcount" -eq 60 ]; then
				Print_Output true "Waiting for NTP to sync..." "$WARN"
			fi
			sleep 1
		done
		if [ "$ntpwaitcount" -ge 300 ]; then
			Print_Output true "NTP failed to sync after 5 minutes. Please resolve!" "$CRIT"
			Clear_Lock
			exit 1
		else
			Print_Output true "NTP synced, $SCRIPT_NAME will now continue" "$PASS"
			/opt/etc/init.d/S33vnstat start >/dev/null 2>&1
			Clear_Lock
		fi
	fi
}

### function based on @Adamm00's Skynet USB wait function ###
Entware_Ready(){
	if [ ! -f /opt/bin/opkg ]; then
		Check_Lock
		sleepcount=1
		while [ ! -f /opt/bin/opkg ] && [ "$sleepcount" -le 10 ]; do
			Print_Output true "Entware not found, sleeping for 10s (attempt $sleepcount of 10)" "$ERR"
			sleepcount="$((sleepcount + 1))"
			sleep 10
		done
		if [ ! -f /opt/bin/opkg ]; then
			Print_Output true "Entware not found and is required for $SCRIPT_NAME to run, please resolve" "$CRIT"
			Clear_Lock
			exit 1
		else
			Print_Output true "Entware found, $SCRIPT_NAME will now continue" "$PASS"
			Clear_Lock
		fi
	fi
}
### ###

if [ -z "$1" ]; then
	NTP_Ready
	Entware_Ready
	Create_Dirs
	Set_Version_Custom_Settings local
	Create_Symlinks
	Auto_Startup create 2>/dev/null
	Auto_Cron create 2>/dev/null
	Auto_ServiceEvent create 2>/dev/null
	Shortcut_Script create
	ScriptHeader
	MainMenu
	exit 0
fi

case "$1" in
	install)
		Check_Lock
		Menu_Install
		exit 0
	;;
	startup)
		Menu_Startup "$2"
		exit 0
	;;
	generate)
		NTP_Ready
		Entware_Ready
		Generate_Images
		Generate_Stats
		exit 0
	;;
	generateimages)
		NTP_Ready
		Entware_Ready
		Generate_Images
		exit 0
	;;
	generatestats)
		NTP_Ready
		Entware_Ready
		Generate_Stats
		Generate_Email
		exit 0
	;;
	service_event)
		if [ "$2" = "start" ] && [ "$3" = "$SCRIPT_NAME" ]; then
			Generate_Images
			Generate_Stats
			exit 0
		elif [ "$2" = "start" ] && echo "$3" | grep "${SCRIPT_NAME}config"; then
			settingstate="$(echo "$3" | sed "s/${SCRIPT_NAME}config//" | cut -f1 -d'_')";
			settingtype="$(echo "$3" | sed "s/${SCRIPT_NAME}config//" | cut -f2 -d'_')";
			Menu_ToggleEmail "$settingstate" "$settingtype"
			exit 0
		elif [ "$2" = "start" ] && [ "$3" = "${SCRIPT_NAME}checkupdate" ]; then
			Update_Check
			exit 0
		elif [ "$2" = "start" ] && [ "$3" = "${SCRIPT_NAME}doupdate" ]; then
			Update_Version force unattended
			exit 0
		fi
		exit 0
	;;
	update)
		Update_Version unattended
		exit 0
	;;
	forceupdate)
		Update_Version force unattended
		exit 0
	;;
	setversion)
		Set_Version_Custom_Settings local
		Set_Version_Custom_Settings server "$SCRIPT_VERSION"
		if [ -z "$2" ]; then
			exec "$0"
		fi
		exit 0
	;;
	checkupdate)
		Update_Check
		exit 0
	;;
	develop)
		SCRIPT_BRANCH="jackyaz-dev"
		SCRIPT_REPO="https://raw.githubusercontent.com/de-vnull/vnstat-on-merlin/$SCRIPT_BRANCH"
		Update_Version force
		exit 0
	;;
	stable)
		SCRIPT_BRANCH="master"
		SCRIPT_REPO="https://raw.githubusercontent.com/de-vnull/vnstat-on-merlin/$SCRIPT_BRANCH"
		Update_Version force
		exit 0
	;;
	uninstall)
		Check_Lock
		Menu_Uninstall
		exit 0
	;;
	*)
		echo "Command not recognised, please try again"
		exit 1
	;;
esac
