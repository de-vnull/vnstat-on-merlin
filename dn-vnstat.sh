#!/bin/sh

#################################################
##                                             ##
##             vnStat on Merlin                ##
##        for AsusWRT-Merlin routers           ##
##                                             ##
##            Concept by dev_null              ##
##          Implemented by Jack Yaz            ##
##    github.com/de-vnull/vnstat-on-merlin     ##
##                                             ##
#################################################

########         Shellcheck directives     ######
# shellcheck disable=SC1091
# shellcheck disable=SC2009
# shellcheck disable=SC2016
# shellcheck disable=SC2018
# shellcheck disable=SC2019
# shellcheck disable=SC2059
# shellcheck disable=SC2086
# shellcheck disable=SC2154
# shellcheck disable=SC2155
# shellcheck disable=SC2181
#################################################

### Start of script variables ###
readonly SCRIPT_NAME="dn-vnstat"
readonly SCRIPT_VERSION="v1.0.2"
SCRIPT_BRANCH="main"
SCRIPT_REPO="https://raw.githubusercontent.com/de-vnull/vnstat-on-merlin/$SCRIPT_BRANCH"
readonly SCRIPT_DIR="/jffs/addons/$SCRIPT_NAME.d"
readonly SCRIPT_CONF="$SCRIPT_DIR/config"
readonly SCRIPT_WEBPAGE_DIR="$(readlink /www/user)"
readonly SCRIPT_WEB_DIR="$SCRIPT_WEBPAGE_DIR/$SCRIPT_NAME"
readonly IMAGE_OUTPUT_DIR="$SCRIPT_DIR/images"
readonly SHARED_DIR="/jffs/addons/shared-jy"
readonly SHARED_REPO="https://raw.githubusercontent.com/jackyaz/shared-jy/master"
readonly SHARED_WEB_DIR="$SCRIPT_WEBPAGE_DIR/shared-jy"
readonly VNSTAT_COMMAND="vnstat --config $SCRIPT_DIR/vnstat.conf"
readonly VNSTATI_COMMAND="vnstati --config $SCRIPT_DIR/vnstat.conf"
readonly VNSTAT_OUTPUT_FILE=/tmp/vnstat.txt
[ -z "$(nvram get odmpid)" ] && ROUTER_MODEL=$(nvram get productid) || ROUTER_MODEL=$(nvram get odmpid)
### End of script variables ###

### Start of output format variables ###
readonly CRIT="\\e[41m"
readonly ERR="\\e[31m"
readonly WARN="\\e[33m"
readonly PASS="\\e[32m"
readonly SETTING="\\e[1m\\e[36m"
### End of output format variables ###

# $1 = print to syslog, $2 = message to print, $3 = log level
Print_Output(){
	if [ "$1" = "true" ]; then
		logger -t "$SCRIPT_NAME" "$2"
	fi
	printf "\\e[1m${3}%s\\e[0m\\n\\n" "$2"
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
	SETTINGSFILE="/jffs/addons/custom_settings.txt"
	case "$1" in
		local)
			if [ -f "$SETTINGSFILE" ]; then
				if [ "$(grep -c "dnvnstat_version_local" $SETTINGSFILE)" -gt 0 ]; then
					if [ "$2" != "$(grep "dnvnstat_version_local" /jffs/addons/custom_settings.txt | cut -f2 -d' ')" ]; then
						sed -i "s/dnvnstat_version_local.*/dnvnstat_version_local $2/" "$SETTINGSFILE"
					fi
				else
					echo "dnvnstat_version_local $2" >> "$SETTINGSFILE"
				fi
			else
				echo "dnvnstat_version_local $2" >> "$SETTINGSFILE"
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
	localver=$(grep "SCRIPT_VERSION=" "/jffs/scripts/$SCRIPT_NAME" | grep -m1 -oE 'v[0-9]{1,2}([.][0-9]{1,2})([.][0-9]{1,2})')
	/usr/sbin/curl -fsL --retry 3 "$SCRIPT_REPO/$SCRIPT_NAME.sh" | grep -qF "de-vnull" || { Print_Output true "404 error detected - stopping update" "$ERR"; return 1; }
	serverver=$(/usr/sbin/curl -fsL --retry 3 "$SCRIPT_REPO/$SCRIPT_NAME.sh" | grep "SCRIPT_VERSION=" | grep -m1 -oE 'v[0-9]{1,2}([.][0-9]{1,2})([.][0-9]{1,2})')
	if uname -m | grep -iq "mips"; then
		doupdate="md5"
		serverver="v1.0.1"
		Set_Version_Custom_Settings "server" "$serverver-hotfix"
		echo 'var updatestatus = "'"$serverver-hotfix"'";'  > "$SCRIPT_WEB_DIR/detect_update.js"
	elif [ "$localver" != "$serverver" ]; then
		doupdate="version"
		Set_Version_Custom_Settings server "$serverver"
		if echo "$localver" | grep -m1 -qoE 'v1{1,2}([.][0-9]{1,2})([.][0-9]{1,2})' && echo "$serverver" | grep -m1 -qoE 'v2{1,2}([.][0-9]{1,2})([.][0-9]{1,2})'; then
			echo 'var updatestatus = "'"$serverver"' - WARNING: MAJOR UPGRADE TO VNSTAT2. VNSTAT.CONF WILL BE RESET WHEN UPDATING FROM V1 TO V2";'  > "$SCRIPT_WEB_DIR/detect_update.js"
		else
			echo 'var updatestatus = "'"$serverver"'";'  > "$SCRIPT_WEB_DIR/detect_update.js"
		fi
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
	if [ -z "$1" ]; then
		updatecheckresult="$(Update_Check)"
		isupdate="$(echo "$updatecheckresult" | cut -f1 -d',')"
		localver="$(echo "$updatecheckresult" | cut -f2 -d',')"
		serverver="$(echo "$updatecheckresult" | cut -f3 -d',')"
		
		if [ "$isupdate" = "version" ]; then
			Print_Output true "New version of $SCRIPT_NAME available - $serverver" "$PASS"
		elif [ "$isupdate" = "md5" ]; then
			Print_Output true "MD5 hash of $SCRIPT_NAME does not match - hotfix available - $serverver" "$PASS"
		fi
		
		if echo "$localver" | grep -m1 -qoE 'v1{1,2}([.][0-9]{1,2})([.][0-9]{1,2})' && echo "$serverver" | grep -m1 -qoE 'v2{1,2}([.][0-9]{1,2})([.][0-9]{1,2})'; then
			Print_Output true "WARNING: MAJOR UPGRADE TO VNSTAT2. VNSTAT.CONF WILL BE RESET WHEN UPDATING FROM V1 TO V2" "$WARN"
		fi
		
		if [ "$isupdate" != "false" ]; then
			printf "\\n\\e[1mDo you want to continue with the update? (y/n)\\e[0m  "
			read -r confirm
			case "$confirm" in
				y|Y)
					if uname -m | grep -iq "mips"; then
						Print_Output true "MIPS support will be maintained on the legacy-v1 branch" "$WARN"
						SCRIPT_BRANCH="legacy-v1"
						SCRIPT_REPO="https://raw.githubusercontent.com/de-vnull/vnstat-on-merlin/$SCRIPT_BRANCH"
						Set_Version_Custom_Settings local v1.0.1
						Set_Version_Custom_Settings server v1.0.1
						/usr/sbin/curl -fsL --retry 3 "$SCRIPT_REPO/$SCRIPT_NAME.sh" -o "/jffs/scripts/$SCRIPT_NAME" && Print_Output true "$SCRIPT_NAME successfully updated"
						exec "$0"
						exit 0
					elif echo "$localver" | grep -m1 -qoE 'v1{1,2}([.][0-9]{1,2})([.][0-9]{1,2})' && echo "$serverver" | grep -m1 -qoE 'v2{1,2}([.][0-9]{1,2})([.][0-9]{1,2})'; then
						Print_Output true "Downloading latest version ($serverver) of $SCRIPT_NAME" "$PASS"
						SCRIPT_BRANCH="vnstat2"
						SCRIPT_REPO="https://raw.githubusercontent.com/de-vnull/vnstat-on-merlin/$SCRIPT_BRANCH"
						Set_Version_Custom_Settings local v2.0.0
						Set_Version_Custom_Settings server v2.0.0
						/usr/sbin/curl -fsL --retry 3 "$SCRIPT_REPO/$SCRIPT_NAME.sh" -o "/jffs/scripts/$SCRIPT_NAME" && Print_Output true "$SCRIPT_NAME successfully updated"
						exec "$0"
						exit 0
					fi
					printf "\\n"
					Update_File shared-jy.tar.gz
					Update_File vnstat-ui.asp
					Update_File vnstat.conf
					Update_File S33vnstat
					/usr/sbin/curl -fsL --retry 3 "$SCRIPT_REPO/$SCRIPT_NAME.sh" -o "/jffs/scripts/$SCRIPT_NAME" && Print_Output true "$SCRIPT_NAME successfully updated"
					chmod 0755 "/jffs/scripts/$SCRIPT_NAME"
					Set_Version_Custom_Settings local "$serverver"
					Set_Version_Custom_Settings server "$serverver"
					Print_Output false "Refreshing vnstat stats..."
					Generate_Images silent
					Generate_Stats silent
					Check_Bandwidth_Usage silent
					Clear_Lock
					PressEnter
					exec "$0"
					exit 0
				;;
				*)
					printf "\\n"
					Clear_Lock
					return 1
				;;
			esac
		else
			Print_Output true "No updates available - latest is $localver" "$WARN"
			Clear_Lock
		fi
	fi
	
	if [ "$1" = "force" ]; then
		if uname -m | grep -iq "mips"; then
			Print_Output true "MIPS support will be maintained on the legacy-v1 branch" "$WARN"
			SCRIPT_BRANCH="legacy-v1"
			SCRIPT_REPO="https://raw.githubusercontent.com/de-vnull/vnstat-on-merlin/$SCRIPT_BRANCH"
			Set_Version_Custom_Settings local v1.0.1
			Set_Version_Custom_Settings server v1.0.1
			/usr/sbin/curl -fsL --retry 3 "$SCRIPT_REPO/$SCRIPT_NAME.sh" -o "/jffs/scripts/$SCRIPT_NAME" && Print_Output true "$SCRIPT_NAME successfully updated"
			if [ -z "$2" ]; then
				exec "$0"
			elif [ "$2" = "unattended" ]; then
				exec "$0" postupdate
			fi
			exit 0
		fi
		localver=$(grep "SCRIPT_VERSION=" "/jffs/scripts/$SCRIPT_NAME" | grep -m1 -oE 'v[0-9]{1,2}([.][0-9]{1,2})([.][0-9]{1,2})')
		serverver=$(/usr/sbin/curl -fsL --retry 3 "$SCRIPT_REPO/$SCRIPT_NAME.sh" | grep "SCRIPT_VERSION=" | grep -m1 -oE 'v[0-9]{1,2}([.][0-9]{1,2})([.][0-9]{1,2})')
		if echo "$localver" | grep -m1 -qoE 'v1{1,2}([.][0-9]{1,2})([.][0-9]{1,2})' && echo "$serverver" | grep -m1 -qoE 'v2{1,2}([.][0-9]{1,2})([.][0-9]{1,2})'; then
			Print_Output true "WARNING: MAJOR UPGRADE TO VNSTAT2. VNSTAT.CONF WILL BE RESET WHEN UPDATING FROM V1 TO V2" "$WARN"
			Print_Output true "Downloading latest version ($serverver) of $SCRIPT_NAME" "$PASS"
			SCRIPT_BRANCH="vnstat2"
			SCRIPT_REPO="https://raw.githubusercontent.com/de-vnull/vnstat-on-merlin/$SCRIPT_BRANCH"
			Set_Version_Custom_Settings local v2.0.0
			Set_Version_Custom_Settings server v2.0.0
			/usr/sbin/curl -fsL --retry 3 "$SCRIPT_REPO/$SCRIPT_NAME.sh" -o "/jffs/scripts/$SCRIPT_NAME" && Print_Output true "$SCRIPT_NAME successfully updated"
			if [ -z "$2" ]; then
				exec "$0"
			elif [ "$2" = "unattended" ]; then
				exec "$0" postupdate
			fi
			exit 0
		fi
		Print_Output true "Downloading latest version ($serverver) of $SCRIPT_NAME" "$PASS"
		Update_File shared-jy.tar.gz
		Update_File vnstat-ui.asp
		Update_File vnstat.conf
		Update_File S33vnstat
		/usr/sbin/curl -fsL --retry 3 "$SCRIPT_REPO/$SCRIPT_NAME.sh" -o "/jffs/scripts/$SCRIPT_NAME" && Print_Output true "$SCRIPT_NAME successfully updated"
		chmod 0755 "/jffs/scripts/$SCRIPT_NAME"
		Set_Version_Custom_Settings local "$serverver"
		Set_Version_Custom_Settings server "$serverver"
		Clear_Lock
		if [ -z "$2" ]; then
			Print_Output false "Refreshing vnstat stats..."
			Generate_Images silent
			Generate_Stats silent
			Check_Bandwidth_Usage silent
			PressEnter
			exec "$0"
		elif [ "$2" = "unattended" ]; then
			exec "$0" postupdate
		fi
		exit 0
	fi
}

Validate_Number(){
	if [ "$2" -eq "$2" ] 2>/dev/null; then
		return 0
	else
		formatted="$(echo "$1" | sed -e 's/|/ /g')"
		if [ -z "$3" ]; then
			Print_Output false "$formatted - $2 is not a number" "$ERR"
		fi
		return 1
	fi
}

Validate_Bandwidth(){
	if echo "$1" | /bin/grep -oq "^[0-9]*\.\?[0-9]\?[0-9]$"; then
		return 0
	else
		return 1
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

Conf_FromSettings(){
	SETTINGSFILE="/jffs/addons/custom_settings.txt"
	TMPFILE="/tmp/dnvnstat_settings.txt"
	if [ -f "$SETTINGSFILE" ]; then
		if [ "$(grep "dnvnstat_" $SETTINGSFILE | grep -v "version" -c)" -gt 0 ]; then
			Print_Output true "Updated settings from WebUI found, merging..." "$PASS"
			cp -a "$SCRIPT_CONF" "$SCRIPT_CONF.bak"
			cp -a "$SCRIPT_DIR/vnstat.conf" "$SCRIPT_DIR/vnstat.conf.bak"
			grep "dnvnstat_" "$SETTINGSFILE" | grep -v "version" > "$TMPFILE"
			sed -i "s/dnvnstat_//g;s/ /=/g" "$TMPFILE"
			warningresetrequired="false"
			while IFS='' read -r line || [ -n "$line" ]; do
				SETTINGNAME="$(echo "$line" | cut -f1 -d'=' | awk '{ print toupper($1) }')"
				SETTINGVALUE="$(echo "$line" | cut -f2 -d'=')"
				if [ "$SETTINGNAME" != "MONTHROTATE" ]; then
					if [ "$SETTINGNAME" = "DATAALLOWANCE" ]; then
						if [ "$(echo "$SETTINGVALUE $(BandwidthAllowance check)" | awk '{print ($1 != $2)}')" -eq 1 ]; then
							warningresetrequired="true"
						fi
					fi
					sed -i "s/$SETTINGNAME=.*/$SETTINGNAME=$SETTINGVALUE/" "$SCRIPT_CONF"
				elif [ "$SETTINGNAME" = "MONTHROTATE" ]; then
					if [ "$SETTINGVALUE" != "$(AllowanceStartDay check)" ]; then
						warningresetrequired="true"
					fi
					sed -i 's/^MonthRotate.*$/MonthRotate '"$SETTINGVALUE"'/' "$SCRIPT_DIR/vnstat.conf"
				fi
			done < "$TMPFILE"
			grep 'dnvnstat_version' "$SETTINGSFILE" > "$TMPFILE"
			sed -i "\\~dnvnstat_~d" "$SETTINGSFILE"
			mv "$SETTINGSFILE" "$SETTINGSFILE.bak"
			cat "$SETTINGSFILE.bak" "$TMPFILE" > "$SETTINGSFILE"
			rm -f "$TMPFILE"
			rm -f "$SETTINGSFILE.bak"
			
			/opt/etc/init.d/S33vnstat restart >/dev/null 2>&1
			TZ=$(cat /etc/TZ)
			export TZ
			
			if [ "$warningresetrequired" = "true" ]; then
				Reset_Allowance_Warnings force
			fi
			Check_Bandwidth_Usage silent
			
			Print_Output true "Merge of updated settings from WebUI completed successfully" "$PASS"
		else
			Print_Output false "No updated settings from WebUI found, no merge necessary" "$PASS"
		fi
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
	ln -s "$SCRIPT_DIR/.vnstatusage" "$SCRIPT_WEB_DIR/vnstatusage.js" 2>/dev/null
	ln -s "$VNSTAT_OUTPUT_FILE" "$SCRIPT_WEB_DIR/vnstatoutput.htm" 2>/dev/null
	ln -s "$SCRIPT_CONF" "$SCRIPT_WEB_DIR/config.htm" 2>/dev/null
	ln -s "$SCRIPT_DIR/vnstat.conf" "$SCRIPT_WEB_DIR/vnstatconf.htm" 2>/dev/null
	ln -s "$IMAGE_OUTPUT_DIR" "$SCRIPT_WEB_DIR/images" 2>/dev/null
	
	if [ ! -d "$SHARED_WEB_DIR" ]; then
		ln -s "$SHARED_DIR" "$SHARED_WEB_DIR" 2>/dev/null
	fi
}

Conf_Exists(){
	if [ -f "$SCRIPT_DIR/vnstat.conf" ]; then
		restartvnstat="false"
		if ! grep -q "^MaxBandwidth 1000" "$SCRIPT_DIR/vnstat.conf"; then
			sed -i 's/^MaxBandwidth.*$/MaxBandwidth 1000/' "$SCRIPT_DIR/vnstat.conf"
			restartvnstat="true"
		fi
		if ! grep -q "^TimeSyncWait 10" "$SCRIPT_DIR/vnstat.conf"; then
			sed -i 's/^TimeSyncWait.*$/TimeSyncWait 10/' "$SCRIPT_DIR/vnstat.conf"
			restartvnstat="true"
		fi
		if ! grep -q "^UpdateInterval 30" "$SCRIPT_DIR/vnstat.conf"; then
			sed -i 's/^UpdateInterval.*$/UpdateInterval 30/' "$SCRIPT_DIR/vnstat.conf"
			restartvnstat="true"
		fi
		if ! grep -q "^UnitMode 0" "$SCRIPT_DIR/vnstat.conf"; then
			sed -i 's/^UnitMode.*$/UnitMode 0/' "$SCRIPT_DIR/vnstat.conf"
			restartvnstat="true"
		fi
		if ! grep -q "^RateUnitMode 0" "$SCRIPT_DIR/vnstat.conf"; then
			sed -i 's/^RateUnitMode.*$/RateUnitMode 0/' "$SCRIPT_DIR/vnstat.conf"
			restartvnstat="true"
		fi
		if ! grep -q "^OutputStyle 0" "$SCRIPT_DIR/vnstat.conf"; then
			sed -i 's/^OutputStyle.*$/OutputStyle 0/' "$SCRIPT_DIR/vnstat.conf"
			restartvnstat="true"
		fi
		if ! grep -q '^MonthFormat "%Y-%m (%d)"' "$SCRIPT_DIR/vnstat.conf"; then
			sed -i 's/^MonthFormat.*$/MonthFormat "%Y-%m (%d)"/' "$SCRIPT_DIR/vnstat.conf"
			restartvnstat="true"
		fi
		
		if [ "$restartvnstat" = "true" ]; then
			/opt/etc/init.d/S33vnstat restart >/dev/null 2>&1
			Generate_Images
			Generate_Stats
			Check_Bandwidth_Usage
		fi
	else
		Update_File vnstat.conf
	fi
	
	if [ -f "$SCRIPT_CONF" ]; then
		dos2unix "$SCRIPT_CONF"
		chmod 0644 "$SCRIPT_CONF"
		sed -i -e 's/WARNINGEMAIL/USAGEEMAIL/;s/"//g' "$SCRIPT_CONF"
		if [ "$(wc -l < "$SCRIPT_CONF")" -eq 3 ]; then
			echo "ALLOWANCEUNIT=G" >> "$SCRIPT_CONF"
		fi
		return 0
	else
		{ echo "DAILYEMAIL=none";  echo "DATAALLOWANCE=1200.00"; echo "USAGEEMAIL=false"; echo "ALLOWANCEUNIT=G"; } > "$SCRIPT_CONF"
		return 1
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
			if [ "$STARTUPLINECOUNT" -gt 0 ]; then
				cru d "${SCRIPT_NAME}_images"
			fi
			
			STARTUPLINECOUNT=$(cru l | grep -c "${SCRIPT_NAME}_stats")
			if [ "$STARTUPLINECOUNT" -gt 0 ]; then
				cru d "${SCRIPT_NAME}_stats"
			fi
			
			STARTUPLINECOUNT=$(cru l | grep -c "${SCRIPT_NAME}_generate")
			if [ "$STARTUPLINECOUNT" -eq 0 ]; then
				cru a "${SCRIPT_NAME}_generate" "*/5 * * * * /jffs/scripts/$SCRIPT_NAME generate"
			fi
			
			STARTUPLINECOUNT=$(cru l | grep -c "${SCRIPT_NAME}_summary")
			if [ "$STARTUPLINECOUNT" -eq 0 ]; then
				cru a "${SCRIPT_NAME}_summary" "59 23 * * * /jffs/scripts/$SCRIPT_NAME summary"
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
			
			STARTUPLINECOUNT=$(cru l | grep -c "${SCRIPT_NAME}_generate")
			if [ "$STARTUPLINECOUNT" -gt 0 ]; then
				cru d "${SCRIPT_NAME}_generate"
			fi
			
			STARTUPLINECOUNT=$(cru l | grep -c "${SCRIPT_NAME}_summary")
			if [ "$STARTUPLINECOUNT" -gt 0 ]; then
				cru d "${SCRIPT_NAME}_summary"
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
	Print_Output true "Mounting WebUI tab for $SCRIPT_NAME" "$PASS"
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
	echo "$SCRIPT_NAME" > "$SCRIPT_WEBPAGE_DIR/$(echo $MyPage | cut -f1 -d'.').title"
	
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
			sed -i "$lineinsbefore"'i,\n{\nmenuName: "Addons",\nindex: "menu_Addons",\ntab: [\n{url: "javascript:var helpwindow=window.open('"'"'/ext/shared-jy/redirect.htm'"'"')", tabName: "Help & Support"},\n{url: "NULL", tabName: "__INHERIT__"}\n]\n}' /tmp/menuTree.js
		fi
		
		sed -i "/url: \"javascript:var helpwindow=window.open('\/ext\/shared-jy\/redirect.htm'/i {url: \"$MyPage\", tabName: \"$SCRIPT_NAME\"}," /tmp/menuTree.js
		
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
				ln -s "/jffs/scripts/$SCRIPT_NAME" /opt/bin
				chmod 0755 "/opt/bin/$SCRIPT_NAME"
			fi
		;;
		delete)
			if [ -f "/opt/bin/$SCRIPT_NAME" ]; then
				rm -f "/opt/bin/$SCRIPT_NAME"
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
		Print_Output false "Custom JFFS Scripts enabled" "$WARN"
	fi

	if [ ! -f /opt/bin/opkg ]; then
		Print_Output false "Entware not detected!" "$ERR"
		CHECKSFAILED="true"
	fi

	if ! Firmware_Version_Check; then
		Print_Output false "Unsupported firmware version detected" "$ERR"
		Print_Output false "$SCRIPT_NAME requires Merlin 384.15/384.13_4 or Fork 43E5 (or later)" "$ERR"
		CHECKSFAILED="true"
	fi

	if [ "$CHECKSFAILED" = "false" ]; then
		Print_Output false "Installing required packages from Entware" "$PASS"
		opkg update
		opkg install vnstat
		opkg install vnstati
		opkg install libjpeg-turbo >/dev/null 2>&1
		opkg install jq
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
	Create_Dirs
	Conf_Exists
	Create_Symlinks
	Auto_Startup create 2>/dev/null
	Auto_Cron create 2>/dev/null
	Auto_ServiceEvent create 2>/dev/null
	Shortcut_Script create
	Process_Upgrade
	if [ ! -f /opt/lib/libjpeg.so ]; then
		opkg update >/dev/null 2>&1
		opkg install libjpeg-turbo >/dev/null 2>&1
	fi
	TZ=$(cat /etc/TZ)
	export TZ
	
	[ -z "$1" ] && Print_Output false "vnstati updating stats for UI" "$PASS"
	
	outputs="s h d t m"   # what images to generate
	
	interface="$(grep "^Interface" "$SCRIPT_DIR/vnstat.conf" | awk '{print $2}' | sed 's/"//g')"
	
	for output in $outputs; do
		$VNSTATI_COMMAND -"$output" -i "$interface" -o "$IMAGE_OUTPUT_DIR/vnstat_$output.png"
	done
	
	sleep 1
	
	for output in $outputs; do
		cp "$IMAGE_OUTPUT_DIR/vnstat_$output.png" "$IMAGE_OUTPUT_DIR/.vnstat_$output.htm"
		rm -f "$IMAGE_OUTPUT_DIR/vnstat_$output.htm"
	done
}

Generate_Stats(){
	Create_Dirs
	Conf_Exists
	Create_Symlinks
	Auto_Startup create 2>/dev/null
	Auto_Cron create 2>/dev/null
	Auto_ServiceEvent create 2>/dev/null
	Shortcut_Script create
	Process_Upgrade
	TZ=$(cat /etc/TZ)
	export TZ
	interface="$(grep "^Interface" "$SCRIPT_DIR/vnstat.conf" | awk '{print $2}' | sed 's/"//g')"
	printf "vnstats as of: %s\\n\\n" "$(date)" > "$VNSTAT_OUTPUT_FILE"
	{
		$VNSTAT_COMMAND -i "$interface" -m;
		$VNSTAT_COMMAND -i "$interface" -w;
		$VNSTAT_COMMAND -i "$interface" -d;
	} >> "$VNSTAT_OUTPUT_FILE"
	[ -z "$1" ] && cat "$VNSTAT_OUTPUT_FILE"
	[ -z "$1" ] && printf "\\n"
	[ -z "$1" ] && Print_Output false "vnstat_totals summary generated" "$PASS"
}

Generate_Email(){
	if [ ! -f /opt/bin/diversion ]; then
		Print_Output true "$SCRIPT_NAME relies on Diversion to send email summaries, and Diversion is not installed" "$ERR"
		Print_Output true "Diversion can be installed using amtm" "$ERR"
		return 1
	elif [ ! -f /opt/share/diversion/.conf/emailpw.enc ] || [ ! -f /opt/share/diversion/.conf/email.conf ]; then
		Print_Output true "$SCRIPT_NAME relies on Diversion to send email summaries, and email settings have not been configured" "$ERR"
		Print_Output true "Navigate to amtm > 1 (Diversion) > c (communication) > 5 (edit email settings, test email) to set this up" "$ERR"
		return 1
	else
		# Adapted from elorimer snbforum's script leveraging Diversion email credentials - agreed by thelonelycoder as well
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
		elif /usr/sbin/openssl aes-256-cbc "$emailPwEnc" -d -in "$PWENCFILE" -pass pass:ditbabot,isoi >/dev/null 2>&1 ; then
			# new OpenSSL 1.1.x converted password with -pbkdf2 flag
			PASSWORD="$(/usr/sbin/openssl aes-256-cbc "$emailPwEnc" -d -in "$PWENCFILE" -pass pass:ditbabot,isoi 2>/dev/null)"
		fi
		
		emailtype="$1"
		if [ "$emailtype" = "daily" ]; then
			Print_Output true "Attempting to send summary statistic email"
			if [ "$(DailyEmail check)" = "text" ];  then
				# plain text email to send #
				{
					echo "From: \"$FRIENDLY_ROUTER_NAME\" <$FROM_ADDRESS>";
					echo "To: \"$TO_NAME\" <$TO_ADDRESS>";
					echo "Subject: $FRIENDLY_ROUTER_NAME - vnstat-stats as of $(date +"%H.%M on %F")";
					echo "Date: $(date -R)";
					echo "";
					printf "%s\\n\\n" "$(grep " usagestring" "$SCRIPT_DIR/.vnstatusage" | cut -f2 -d'"')";
					printf "%s\\n\\n" "$(grep " realusagestring" "$SCRIPT_DIR/.vnstatusage" | cut -f2 -d'"')";
				} > /tmp/mail.txt
				cat "$VNSTAT_OUTPUT_FILE" >>/tmp/mail.txt
			elif [ "$(DailyEmail check)" = "html" ]; then
				# html message to send #
				{
					echo "From: \"$FRIENDLY_ROUTER_NAME\" <$FROM_ADDRESS>";
					echo "To: \"$TO_NAME\" <$TO_ADDRESS>";
					echo "Subject: $FRIENDLY_ROUTER_NAME - vnstat-stats as of $(date +"%H.%M on %F")";
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
				
				outputs="s h d t m"
				echo "<html><body><p>Welcome to your dn-vnstat stats email!</p>" > /tmp/message.html
				echo "<p>$(grep " usagestring" "$SCRIPT_DIR/.vnstatusage" | cut -f2 -d'"')</p>" >> /tmp/message.html
				echo "<p>$(grep " realusagestring" "$SCRIPT_DIR/.vnstatusage" | cut -f2 -d'"')</p>" >> /tmp/message.html
				
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
				
				Encode_Text vnstat.txt "$(cat "$VNSTAT_OUTPUT_FILE")" /tmp/mail.txt
				
				{
					echo "--MULTIPART-RELATED-BOUNDARY--";
					echo "";
					echo "--MULTIPART-MIXED-BOUNDARY--";
				} >> /tmp/mail.txt
			fi
		elif [ "$emailtype" = "usage" ]; then
			[ -z "$5" ] && Print_Output true "Attempting to send bandwidth usage email"
			usagepercentage="$2"
			usagestring="$3"
			realusagestring="$4"
			# plain text email to send #
			{
				echo "From: \"$FRIENDLY_ROUTER_NAME\" <$FROM_ADDRESS>";
				echo "To: \"$TO_NAME\" <$TO_ADDRESS>";
				echo "Subject: $FRIENDLY_ROUTER_NAME - vnstat data usage $usagepercentage warning - $(date +"%H.%M on %F")";
				echo "Date: $(date -R)";
				echo "";
			} > /tmp/mail.txt
			printf "%s\\n\\n" "$usagestring" >> /tmp/mail.txt
			printf "%s" "$realusagestring" >> /tmp/mail.txt
		fi
		
		#Send Email
		/usr/sbin/curl -s --show-error --url "$PROTOCOL://$SMTP:$PORT" \
		--mail-from "$FROM_ADDRESS" --mail-rcpt "$TO_ADDRESS" \
		--upload-file /tmp/mail.txt \
		--ssl-reqd \
		--user "$USERNAME:$PASSWORD" $SSL_FLAG
		# shellcheck disable=SC2181
		if [ $? -eq 0 ]; then
			[ -z "$5" ] && Print_Output true "Email sent successfully" "$PASS"
			rm -f /tmp/mail.txt
			return 0
		else
			echo ""
			[ -z "$5" ] && Print_Output true "Email failed to send" "$ERR"
			rm -f /tmp/mail.txt
			return 1
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

DailyEmail(){
	case "$1" in
		enable)
			if [ -z "$2" ]; then
				ScriptHeader
				exitmenu="false"
				printf "\\n\\e[1mA choice of emails is available:\\e[0m\\n"
				printf "1.    HTML (includes images from WebUI + summary stats as attachment)\\n"
				printf "2.    Plain text (summary stats only)\\n"
				printf "\\ne.    Exit to main menu\\n"
				
				while true; do
					printf "\\n\\e[1mChoose an option:\\e[0m  "
					read -r emailtype
					case "$emailtype" in
						1)
							sed -i 's/^DAILYEMAIL.*$/DAILYEMAIL=html/' "$SCRIPT_CONF"
							break
						;;
						2)
							sed -i 's/^DAILYEMAIL.*$/DAILYEMAIL=text/' "$SCRIPT_CONF"
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
			else
				sed -i 's/^DAILYEMAIL.*$/DAILYEMAIL='"$2"'/' "$SCRIPT_CONF"
			fi
			
			Generate_Email daily
			if [ $? -eq 1 ]; then
				DailyEmail disable
			fi
		;;
		disable)
			sed -i 's/^DAILYEMAIL.*$/DAILYEMAIL=none/' "$SCRIPT_CONF"
		;;
		check)
			DAILYEMAIL=$(grep "DAILYEMAIL" "$SCRIPT_CONF" | cut -f2 -d"=")
			echo "$DAILYEMAIL"
		;;
	esac
}

UsageEmail(){
	case "$1" in
		enable)
			sed -i 's/^USAGEEMAIL.*$/USAGEEMAIL=true/' "$SCRIPT_CONF"
			Check_Bandwidth_Usage
		;;
		disable)
			sed -i 's/^USAGEEMAIL.*$/USAGEEMAIL=false/' "$SCRIPT_CONF"
		;;
		check)
			USAGEEMAIL=$(grep "USAGEEMAIL" "$SCRIPT_CONF" | cut -f2 -d"=")
			if [ "$USAGEEMAIL" = "true" ]; then return 0; else return 1; fi
		;;
	esac
}

BandwidthAllowance(){
	case "$1" in
		update)
			bandwidth="$(echo "$2" | awk '{printf("%.2f", $1);}')"
			sed -i 's/^DATAALLOWANCE.*$/DATAALLOWANCE='"$bandwidth"'/' "$SCRIPT_CONF"
			if [ -z "$3" ]; then
				Reset_Allowance_Warnings force
			fi
			Check_Bandwidth_Usage
		;;
		check)
			DATAALLOWANCE=$(grep "DATAALLOWANCE" "$SCRIPT_CONF" | cut -f2 -d"=")
			echo "$DATAALLOWANCE"
		;;
	esac
}

AllowanceStartDay(){
	case "$1" in
		update)
			sed -i 's/^MonthRotate .*$/MonthRotate '"$2"'/' "$SCRIPT_DIR/vnstat.conf"
			/opt/etc/init.d/S33vnstat restart >/dev/null 2>&1
			TZ=$(cat /etc/TZ)
			export TZ
			Reset_Allowance_Warnings force
			Check_Bandwidth_Usage
		;;
		check)
			MonthRotate=$(grep "^MonthRotate " "$SCRIPT_DIR/vnstat.conf" | cut -f2 -d" ")
			echo "$MonthRotate"
		;;
	esac
}

AllowanceUnit(){
	case "$1" in
		update)
		sed -i 's/^ALLOWANCEUNIT.*$/ALLOWANCEUNIT='"$2"'/' "$SCRIPT_CONF"
		;;
		check)
			ALLOWANCEUNIT=$(grep "ALLOWANCEUNIT" "$SCRIPT_CONF" | cut -f2 -d"=")
			echo "${ALLOWANCEUNIT}B"
		;;
	esac
}

Reset_Allowance_Warnings(){
	if [ "$(date +%d | awk '{printf("%s", $1+1);}')" -eq "$(AllowanceStartDay check)" ] || [ "$1" = "force" ]; then
		rm -f "$SCRIPT_DIR/.warning75"
		rm -f "$SCRIPT_DIR/.warning90"
		rm -f "$SCRIPT_DIR/.warning100"
	fi
}

Check_Bandwidth_Usage(){
	if [ ! -f /opt/bin/jq ]; then
		opkg update
		opkg install jq
	fi
	TZ=$(cat /etc/TZ)
	export TZ
	
	interface="$(grep "^Interface" "$SCRIPT_DIR/vnstat.conf" | awk '{print $2}' | sed 's/"//g')"
	
	rawbandwidthused="$($VNSTAT_COMMAND -i "$interface" --json m | jq -r '.interfaces[].traffic.months[0] | .rx + .tx')"
	userLimit="$(BandwidthAllowance check)"
	
	scalefactor=$((1000*1000))
	if AllowanceUnit check | grep -q T; then
		scalefactor=$((1000*1000*1000))
	fi
	bandwidthused=$(echo "$rawbandwidthused $scalefactor" | awk '{printf("%.2f\n", $1*1.024/$2);}')
	
	realscalefactor=$((1024*1024))
	realbandwidthusedg=$(echo "$rawbandwidthused $realscalefactor" | awk '{printf("%.2f\n", $1/$2);}')
	realscalefactor=$((realscalefactor*1024))
	realbandwidthusedt=$(echo "$rawbandwidthused $realscalefactor" | awk '{printf("%.2f\n", $1/$2);}')
	realusagestring="vnStat will show your usage as ${realbandwidthusedg}GiB / ${realbandwidthusedt}TiB"
	
	bandwidthpercentage=""
	usagestring=""
	if [ "$(echo "$userLimit 0" | awk '{print ($1 == $2)}')" -eq 1 ]; then
		bandwidthpercentage="N/A"
		usagestring="You have used ${bandwidthused}$(AllowanceUnit check) of data this cycle, the cycle starts on day $(AllowanceStartDay check) of the month"
	else
		bandwidthpercentage=$(echo "$bandwidthused $userLimit" | awk '{printf("%.2f\n", $1*100/$2);}')
		usagestring="You have used ${bandwidthpercentage}% (${bandwidthused}$(AllowanceUnit check)) of your ${userLimit}$(AllowanceUnit check) cycle allowance, the cycle starts on day $(AllowanceStartDay check) of the month"
	fi
	
	[ -z "$1" ] && Print_Output false "$usagestring"
	[ -z "$1" ] && Print_Output false "$realusagestring"
	
	if [ "$bandwidthpercentage" = "N/A" ] || [ "$(echo "$bandwidthpercentage 75" | awk '{print ($1 < $2)}')" -eq 1 ]; then
		echo "var usagethreshold = false;" > "$SCRIPT_DIR/.vnstatusage"
		echo 'var thresholdstring = "";' >> "$SCRIPT_DIR/.vnstatusage"
	elif [ "$(echo "$bandwidthpercentage 75" | awk '{print ($1 >= $2)}')" -eq 1 ] && [ "$(echo "$bandwidthpercentage 90" | awk '{print ($1 < $2)}')" -eq 1 ]; then
		[ -z "$1" ] && Print_Output false "Data use is at or above 75%" "$WARN"
		echo "var usagethreshold = true;" > "$SCRIPT_DIR/.vnstatusage"
		echo 'var thresholdstring = "Data use is at or above 75%";' >> "$SCRIPT_DIR/.vnstatusage"
		if UsageEmail check && [ ! -f "$SCRIPT_DIR/.warning75" ]; then
			if [ -n "$1" ]; then
				Generate_Email usage "75%" "$usagestring" "$realusagestring" silent
			else
				Generate_Email usage "75%" "$usagestring" "$realusagestring"
			fi
			touch "$SCRIPT_DIR/.warning75"
		fi
	elif [ "$(echo "$bandwidthpercentage 90" | awk '{print ($1 >= $2)}')" -eq 1 ]  && [ "$(echo "$bandwidthpercentage 100" | awk '{print ($1 < $2)}')" -eq 1 ]; then
		[ -z "$1" ] && Print_Output false "Data use is at or above 90%" "$ERR"
		echo "var usagethreshold = true;" > "$SCRIPT_DIR/.vnstatusage"
		echo 'var thresholdstring = "Data use is at or above 90%";' >> "$SCRIPT_DIR/.vnstatusage"
		if UsageEmail check && [ ! -f "$SCRIPT_DIR/.warning90" ]; then
			if [ -n "$1" ]; then
				Generate_Email usage "90%" "$usagestring" "$realusagestring" silent
			else
				Generate_Email usage "90%" "$usagestring" "$realusagestring"
			fi
			touch "$SCRIPT_DIR/.warning90"
		fi
	elif [ "$(echo "$bandwidthpercentage 100" | awk '{print ($1 >= $2)}')" -eq 1 ]; then
		[ -z "$1" ] && Print_Output false "Data use is at or above 100%" "$CRIT"
		echo "var usagethreshold = true;" > "$SCRIPT_DIR/.vnstatusage"
		echo 'var thresholdstring = "Data use is at or above 100%";' >> "$SCRIPT_DIR/.vnstatusage"
		if UsageEmail check && [ ! -f "$SCRIPT_DIR/.warning100" ]; then
			if [ -n "$1" ]; then
				Generate_Email usage "100%" "$usagestring" "$realusagestring" silent
			else
				Generate_Email usage "100%" "$usagestring" "$realusagestring"
			fi
			touch "$SCRIPT_DIR/.warning100"
		fi
	fi
	{
		printf "var usagestring = \"%s\";\\n" "$usagestring"
		printf "var realusagestring = \"%s\";\\n" "$realusagestring"
		printf "var daterefeshed = \"%s\";\\n" "$(date +"%Y-%m-%d %T")"
	} >> "$SCRIPT_DIR/.vnstatusage"
}

Process_Upgrade(){
	if [ ! -f "$SCRIPT_DIR/.vnstatusage" ]; then
		{
			echo "var usagethreshold = false;"
			echo 'var thresholdstring = "";'
			echo 'var usagestring = "Not enough data gathered by vnstat";'
		} > "$SCRIPT_DIR/.vnstatusage"
	fi
	if [ -f "$SCRIPT_DIR/.emailenabled" ]; then
		rm -f "$SCRIPT_DIR/.emailenabled"
	fi
	if [ -f "$IMAGE_OUTPUT_DIR/vnstat.png" ]; then
		rm -f "$IMAGE_OUTPUT_DIR/vnstat.png"
	fi
	if [ ! -f /opt/lib/libjpeg.so ]; then
		opkg update >/dev/null 2>&1
		opkg install libjpeg-turbo >/dev/null 2>&1
	fi
	if [ ! -f /opt/bin/jq ]; then
		opkg update
		opkg install jq
	fi
	rm -f "$SCRIPT_DIR/.znewdefaults"
}

ScriptHeader(){
	clear
	printf "\\n"
	printf "\\e[1m################################################\\e[0m\\n"
	printf "\\e[1m##                                            ##\\e[0m\\n"
	printf "\\e[1m##            vnStat on Merlin                ##\\e[0m\\n"
	printf "\\e[1m##       for AsusWRT-Merlin routers           ##\\e[0m\\n"
	printf "\\e[1m##                                            ##\\e[0m\\n"
	printf "\\e[1m##            %s on %-11s           ##\\e[0m\\n" "$SCRIPT_VERSION" "$ROUTER_MODEL"
	printf "\\e[1m##                                            ## \\e[0m\\n"
	printf "\\e[1m##    github.com/de-vnull/vnstat-on-merlin    ##\\e[0m\\n"
	printf "\\e[1m##                                            ##\\e[0m\\n"
	printf "\\e[1m################################################\\e[0m\\n"
	printf "\\n"
}

MainMenu(){
	MENU_DAILYEMAIL="$(DailyEmail check)"
	if [ "$MENU_DAILYEMAIL" = "html" ]; then
		MENU_DAILYEMAIL="${PASS}ENABLED - HTML"
	elif [ "$MENU_DAILYEMAIL" = "text" ]; then
		MENU_DAILYEMAIL="${PASS}ENABLED - TEXT"
	elif [ "$MENU_DAILYEMAIL" = "none" ]; then
		MENU_DAILYEMAIL="${ERR}DISABLED"
	fi
	MENU_USAGE_ENABLED=""
	if UsageEmail check; then MENU_USAGE_ENABLED="${PASS}ENABLED"; else MENU_USAGE_ENABLED="${ERR}DISABLED"; fi
	MENU_BANDWIDTHALLOWANCE=""
	if [ "$(echo "$(BandwidthAllowance check) 0" | awk '{print ($1 == $2)}')" -eq 1 ]; then
		MENU_BANDWIDTHALLOWANCE="UNLIMITED"
	else
		MENU_BANDWIDTHALLOWANCE="$(BandwidthAllowance check)$(AllowanceUnit check)"
	fi
	printf "1.    Update stats now\\n\\n"
	printf "2.    Toggle emails for daily summary stats\\n      Currently: \\e[1m$MENU_DAILYEMAIL\\e[0m\\n\\n"
	printf "3.    Toggle emails for data usage warnings\\n      Currently: \\e[1m$MENU_USAGE_ENABLED\\e[0m\\n\\n"
	printf "4.    Set bandwidth allowance for data usage warnings\\n      Currently: ${SETTING}%s\\e[0m\\n\\n" "$MENU_BANDWIDTHALLOWANCE"
	printf "5.    Set unit for bandwidth allowance\\n      Currently: ${SETTING}%s\\e[0m\\n\\n" "$(AllowanceUnit check)"
	printf "6.    Set start day of cycle for bandwidth allowance\\n      Currently: ${SETTING}%s\\e[0m\\n\\n" "Day $(AllowanceStartDay check) of month"
	printf "b.    Check bandwidth usage now\\n      ${SETTING}%s\\n      %s\\e[0m\\n\\n" "$(grep " usagestring" "$SCRIPT_DIR/.vnstatusage" | cut -f2 -d'"')" "$(grep " realusagestring" "$SCRIPT_DIR/.vnstatusage" | cut -f2 -d'"')"
	printf "v.    Edit vnstat config\\n\\n"
	printf "u.    Check for updates\\n"
	printf "uf.   Force update %s with latest version\\n\\n" "$SCRIPT_NAME"
	printf "e.    Exit menu for %s\\n\\n" "$SCRIPT_NAME"
	printf "z.    Uninstall %s\\n" "$SCRIPT_NAME"
	printf "\\n"
	printf "\\e[1m################################################\\e[0m\\n"
	printf "\\n"
	
	while true; do
		printf "Choose an option:  "
		read -r menu
		case "$menu" in
			1)
				printf "\\n"
				if Check_Lock menu; then
					Generate_Images
					Generate_Stats
					Clear_Lock
				fi
				PressEnter
				break
			;;
			2)
				printf "\\n"
				if [ "$(DailyEmail check)" != "none" ]; then
					DailyEmail disable
				elif [ "$(DailyEmail check)" = "none" ]; then
					DailyEmail enable
				fi
				PressEnter
				break
			;;
			3)
				printf "\\n"
				if UsageEmail check; then
					UsageEmail disable
				elif ! UsageEmail check; then
					UsageEmail enable
				fi
				PressEnter
				break
			;;
			4)
				printf "\\n"
				if Check_Lock menu; then
					Menu_BandwidthAllowance
				fi
				PressEnter
				break
			;;
			5)
				printf "\\n"
				if Check_Lock menu; then
					Menu_AllowanceUnit
				fi
				PressEnter
				break
			;;
			6)
				printf "\\n"
				if Check_Lock menu; then
					Menu_AllowanceStartDay
				fi
				PressEnter
				break
			;;
			b)
				printf "\\n"
				if Check_Lock menu; then
					Check_Bandwidth_Usage
					Clear_Lock
				fi
				PressEnter
				break
			;;
			v)
				printf "\\n"
				if Check_Lock menu; then
					Menu_Edit
				fi
				break
			;;
			u)
				printf "\\n"
				if Check_Lock menu; then
					Update_Version
					Clear_Lock
				fi
				PressEnter
				break
			;;
			uf)
				printf "\\n"
				if Check_Lock menu; then
					Update_Version force
					Clear_Lock
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
					printf "\\n\\e[1mAre you sure you want to uninstall %s? (y/n)\\e[0m  " "$SCRIPT_NAME"
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
	Print_Output true "Welcome to $SCRIPT_NAME $SCRIPT_VERSION, a script by dev_null and Jack Yaz"
	sleep 1
	
	Print_Output false "Checking your router meets the requirements for $SCRIPT_NAME"
	
	if ! Check_Requirements; then
		Print_Output false "Requirements for $SCRIPT_NAME not met, please see above for the reason(s)" "$CRIT"
		PressEnter
		Clear_Lock
		rm -f "/jffs/scripts/$SCRIPT_NAME" 2>/dev/null
		exit 1
	fi
	
	if [ -n "$(ls -A /opt/var/lib/vnstat 2>/dev/null)" ] && [ -f /opt/bin/vnstat ]; then
		if [ ! -d "$SCRIPT_DIR" ]; then
			mkdir -p "$SCRIPT_DIR"
		fi
		$VNSTAT_COMMAND --exportdb > "$SCRIPT_DIR/vnstat-data.bak"
	fi
	
	IFACE=""
	printf "\\n\\e[1mWAN Interface detected as %s\\e[0m\\n" "$(Get_WAN_IFace)"
	while true; do
		printf "\\n\\e[1mIs this correct? (y/n)\\e[0m  "
		read -r confirm
		case "$confirm" in
			y|Y)
				IFACE="$(Get_WAN_IFace)"
				break
			;;
			n|N)
				while true; do
					printf "\\n\\e[1mPlease enter correct interface:\\e[0m  "
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
	Conf_Exists
	Set_Version_Custom_Settings local "$SCRIPT_VERSION"
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
	
	Process_Upgrade
	
	if [ -n "$(pidof vnstatd)" ];then
		Print_Output false "Sleeping for 60s before generating initial stats" "$WARN"
		sleep 60
		Generate_Images
		Generate_Stats
		Check_Bandwidth_Usage silent
	else
		Print_Output false "vnstatd not running, please check system log" "$ERR"
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
	Conf_Exists
	Create_Symlinks
	Auto_Startup create 2>/dev/null
	Auto_Cron create 2>/dev/null
	Auto_ServiceEvent create 2>/dev/null
	Shortcut_Script create
	Mount_WebUI
	Clear_Lock
}

Menu_BandwidthAllowance(){
	exitmenu="false"
	bandwidthallowance=""
	ScriptHeader
	
	while true; do
		printf "\\n\\e[1mPlease enter your monthly bandwidth allowance\\n(%s, 0 = unlimited, max. 2 decimals):\\e[0m  " "$(AllowanceUnit check)"
		read -r allowance
		
		if [ "$allowance" = "e" ]; then
			exitmenu="exit"
			break
		elif ! Validate_Bandwidth "$allowance"; then
			printf "\\n\\e[31mPlease enter a valid number (%s, 0 = unlimited, max. 2 decimals)\\e[0m\\n" "$(AllowanceUnit check)"
		else
			bandwidthallowance="$allowance"
			printf "\\n"
			break
		fi
	done
	
	if [ "$exitmenu" != "exit" ]; then
		BandwidthAllowance update "$bandwidthallowance"
	fi
	
	Clear_Lock
}

Menu_AllowanceUnit(){
	exitmenu="false"
	allowanceunit=""
	prevallowanceunit="$(AllowanceUnit check)"
	unitsuffix="$(AllowanceUnit check | sed 's/T//;s/G//;')"
	ScriptHeader
	
	while true; do
		printf "\\n\\e[1mPlease select the unit to use for bandwidth allowance:\\e[0m\\n"
		printf "1.    G%s\\n" "$unitsuffix"
		printf "2.    T%s\\n\\n" "$unitsuffix"
		printf "Choose an option:  "
		read -r unitchoice
		case "$unitchoice" in
			1)
				allowanceunit="G"
				printf "\\n"
				break
			;;
			2)
				allowanceunit="T"
				printf "\\n"
				break
			;;
			e)
				exitmenu="exit"
				break
			;;
			*)
				printf "\\nPlease choose a valid option\\n\\n"
			;;
		esac
	done
	if [ "$exitmenu" != "exit" ]; then
		AllowanceUnit update "$allowanceunit"
		
		allowanceunit="$(AllowanceUnit check)"
		if [ "$prevallowanceunit" != "$allowanceunit" ]; then
			scalefactor=1000
			#if echo "$allowanceunit" | grep -q i ; then
			#	scalefactor=1024
			#fi
		
			scaletype="none"
			if [ "$prevallowanceunit" != "$(AllowanceUnit check)" ]; then
				if echo "$prevallowanceunit" | grep -q G && AllowanceUnit check | grep -q T; then
					scaletype="divide"
				elif echo "$prevallowanceunit" | grep -q T && AllowanceUnit check | grep -q G; then
					scaletype="multiply"
				fi
			fi
		
			if [ "$scaletype" != "none" ]; then
				bandwidthallowance="$(BandwidthAllowance check)"
				if [ "$scaletype" = "multiply" ]; then
					bandwidthallowance=$(echo "$(BandwidthAllowance check) $scalefactor" | awk '{printf("%.2f\n", $1*$2);}')
				elif [ "$scaletype" = "divide" ]; then
					bandwidthallowance=$(echo "$(BandwidthAllowance check) $scalefactor" | awk '{printf("%.2f\n", $1/$2);}')
				fi
				BandwidthAllowance update "$bandwidthallowance" noreset
			fi
		fi
	fi
	
	Clear_Lock
}

Menu_AllowanceStartDay(){
	exitmenu="false"
	allowancestartday=""
	ScriptHeader
	
	while true; do
		printf "\\n\\e[1mPlease enter day of month that your bandwidth allowance\\nresets (1-28):\\e[0m  "
		read -r startday
		
		if [ "$startday" = "e" ]; then
			exitmenu="exit"
			break
		elif ! Validate_Number "" "$startday" silent; then
			printf "\\n\\e[31mPlease enter a valid number (1-28)\\e[0m\\n"
		else
			if [ "$startday" -lt 1 ] || [ "$startday" -gt 28 ]; then
				printf "\\n\\e[31mPlease enter a number between 1 and 28\\e[0m\\n"
			else
				allowancestartday="$startday"
				printf "\\n"
				break
			fi
		fi
	done
	
	if [ "$exitmenu" != "exit" ]; then
		AllowanceStartDay update "$allowancestartday"
	fi
	
	Clear_Lock
}

Menu_Edit(){
	texteditor=""
	exitmenu="false"
	
	printf "\\n\\e[1mA choice of text editors is available:\\e[0m\\n"
	printf "1.    nano (recommended for beginners)\\n"
	printf "2.    vi\\n"
	printf "\\ne.    Exit to main menu\\n"
	
	while true; do
		printf "\\n\\e[1mChoose an option:\\e[0m  "
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
			TZ=$(cat /etc/TZ)
			export TZ
			Check_Bandwidth_Usage silent
			Clear_Lock
			printf "\\n"
			PressEnter
		fi
	fi
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
	
	rm -f /opt/etc/init.d/S33vnstat
	rm -f /opt/etc/vnstat.conf
	
	Reset_Allowance_Warnings force
	rm -f "$SCRIPT_DIR/.vnstatusage"
	rm -rf "$IMAGE_OUTPUT_DIR"
	
	SETTINGSFILE=/jffs/addons/custom_settings.txt
	sed -i '/dnvnstat_version_local/d' "$SETTINGSFILE"
	sed -i '/dnvnstat_version_server/d' "$SETTINGSFILE"
	
	printf "\\n\\e[1mWould you like to keep the vnstat\\ndata files and configuration? (y/n)\\e[0m  "
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
		ntpwaitcount=0
		while [ "$(nvram get ntp_ready)" -eq 0 ] && [ "$ntpwaitcount" -lt 600 ]; do
			ntpwaitcount="$((ntpwaitcount + 30))"
			Print_Output true "Waiting for NTP to sync..." "$WARN"
			sleep 30
		done
		if [ "$ntpwaitcount" -ge 600 ]; then
			Print_Output true "NTP failed to sync after 10 minutes. Please resolve!" "$CRIT"
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
	Conf_Exists
	Create_Symlinks
	Auto_Startup create 2>/dev/null
	Auto_Cron create 2>/dev/null
	Auto_ServiceEvent create 2>/dev/null
	Shortcut_Script create
	Process_Upgrade
	ScriptHeader
	if [ ! -f "$IMAGE_OUTPUT_DIR/.vnstat_m.htm" ]; then
		Print_Output false "Refreshing vnstat stats..."
		Generate_Images silent
		Generate_Stats silent
		Check_Bandwidth_Usage silent
		ScriptHeader
	fi
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
		Check_Lock
		Generate_Images silent
		Generate_Stats silent
		Check_Bandwidth_Usage silent
		Clear_Lock
		exit 0
	;;
	summary)
		NTP_Ready
		Entware_Ready
		Reset_Allowance_Warnings
		Generate_Images silent
		Generate_Stats silent
		Check_Bandwidth_Usage silent
		if [ "$(DailyEmail check)" != "none" ]; then
			Generate_Email daily
		fi
		exit 0
	;;
	service_event)
		if [ "$2" = "start" ] && [ "$3" = "$SCRIPT_NAME" ]; then
			Check_Lock webui
			echo 'var vnstatstatus = "InProgress";' > /tmp/detect_vnstat.js
			Generate_Images silent
			Generate_Stats silent
			Check_Bandwidth_Usage silent
			echo 'var vnstatstatus = "Done";' > /tmp/detect_vnstat.js
			Clear_Lock
			exit 0
		elif [ "$2" = "start" ] && echo "$3" | grep "${SCRIPT_NAME}config"; then
			Conf_FromSettings
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
		Update_Version
		exit 0
	;;
	forceupdate)
		Update_Version force
		exit 0
	;;
	postupdate)
		Process_Upgrade
		Create_Dirs
		Conf_Exists
		Create_Symlinks
		Auto_Startup create 2>/dev/null
		Auto_Cron create 2>/dev/null
		Auto_ServiceEvent create 2>/dev/null
		Shortcut_Script create
		Generate_Images silent
		Generate_Stats silent
		Check_Bandwidth_Usage silent
		exit 0
	;;
	uninstall)
		Check_Lock
		Menu_Uninstall
		exit 0
	;;
	v2)
		SCRIPT_BRANCH="vnstat2"
		SCRIPT_REPO="https://raw.githubusercontent.com/de-vnull/vnstat-on-merlin/$SCRIPT_BRANCH"
		Update_Version force
		exit 0
	;;
	develop)
		SCRIPT_BRANCH="jackyaz-dev"
		SCRIPT_REPO="https://raw.githubusercontent.com/de-vnull/vnstat-on-merlin/$SCRIPT_BRANCH"
		Update_Version force
		exit 0
	;;
	stable)
		SCRIPT_BRANCH="main"
		SCRIPT_REPO="https://raw.githubusercontent.com/de-vnull/vnstat-on-merlin/$SCRIPT_BRANCH"
		Update_Version force
		exit 0
	;;
	*)
		echo "Command not recognised, please try again"
		exit 1
	;;
esac
