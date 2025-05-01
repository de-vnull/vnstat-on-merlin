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
# Last Modified: 2025-Apr-29
#------------------------------------------------

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
readonly SCRIPT_VERSION="v2.0.7"
SCRIPT_BRANCH="main"
SCRIPT_REPO="https://raw.githubusercontent.com/de-vnull/vnstat-on-merlin/$SCRIPT_BRANCH"
readonly SCRIPT_DIR="/jffs/addons/$SCRIPT_NAME.d"
readonly SCRIPT_WEBPAGE_DIR="$(readlink -f /www/user)"
readonly SCRIPT_WEB_DIR="$SCRIPT_WEBPAGE_DIR/$SCRIPT_NAME"
readonly TEMP_MENU_TREE="/tmp/menuTree.js"
readonly SHARED_DIR="/jffs/addons/shared-jy"
readonly SHARED_REPO="https://raw.githubusercontent.com/jackyaz/shared-jy/master"
readonly SHARED_WEB_DIR="$SCRIPT_WEBPAGE_DIR/shared-jy"

[ -z "$(nvram get odmpid)" ] && ROUTER_MODEL="$(nvram get productid)" || ROUTER_MODEL="$(nvram get odmpid)"
[ -f /opt/bin/sqlite3 ] && SQLITE3_PATH=/opt/bin/sqlite3 || SQLITE3_PATH=/usr/sbin/sqlite3

##-------------------------------------##
## Added by Martinski W. [2025-Apr-27] ##
##-------------------------------------##
readonly scriptVersRegExp="v[0-9]{1,2}([.][0-9]{1,2})([.][0-9]{1,2})"
readonly webPageMenuAddons="menuName: \"Addons\","
readonly webPageHelpSupprt="tabName: \"Help & Support\"},"
readonly webPageFileRegExp="user([1-9]|[1-2][0-9])[.]asp"
readonly webPageLineTabExp="\{url: \"$webPageFileRegExp\", tabName: "
readonly webPageLineRegExp="${webPageLineTabExp}\"$SCRIPT_NAME\"\},"
readonly BEGIN_MenuAddOnsTag="/\*\*BEGIN:_AddOns_\*\*/"
readonly ENDIN_MenuAddOnsTag="/\*\*ENDIN:_AddOns_\*\*/"
readonly SHARE_TEMP_DIR="/opt/share/tmp"

### End of script variables ###

### Start of output format variables ###
readonly CRIT="\\e[41m"
readonly ERR="\\e[31m"
readonly WARN="\\e[33m"
readonly PASS="\\e[32m"
readonly BOLD="\\e[1m"
readonly SETTING="${BOLD}\\e[36m"
readonly CLEARFORMAT="\\e[0m"

##----------------------------------------##
## Modified by Martinski W. [2025-Apr-28] ##
##----------------------------------------##
readonly CLRct="\e[0m"
readonly REDct="\e[1;31m"
readonly GRNct="\e[1;32m"
readonly CritBREDct="\e[30;101m"
readonly WarnBYLWct="\e[30;103m"
readonly WarnBMGNct="\e[30;105m"

### End of output format variables ###

# Give priority to built-in binaries #
export PATH="/bin:/usr/bin:/sbin:/usr/sbin:$PATH"

##----------------------------------------##
## Modified by Martinski W. [2025-Apr-27] ##
##----------------------------------------##
# $1 = print to syslog, $2 = message to print, $3 = log level
Print_Output()
{
	local prioStr  prioNum
	if [ $# -gt 2 ] && [ -n "$3" ]
	then prioStr="$3"
	else prioStr="NOTICE"
	fi
	if [ "$1" = "true" ]
	then
		case "$prioStr" in
		    "$CRIT") prioNum=2 ;;
		     "$ERR") prioNum=3 ;;
		    "$WARN") prioNum=4 ;;
		    "$PASS") prioNum=6 ;; #INFO#
		          *) prioNum=5 ;; #NOTICE#
		esac
		logger -t "$SCRIPT_NAME" -p $prioNum "$2"
	fi
	printf "${BOLD}${3}%s${CLEARFORMAT}\n\n" "$2"
}

### Check firmware version contains the "am_addons" feature flag ###
Firmware_Version_Check()
{
	if nvram get rc_support | grep -qF "am_addons"; then
		return 0
	else
		return 1
	fi
}

### Create "lock" file to ensure script only allows 1 concurrent process for certain actions ###
### Code for these functions inspired by https://github.com/Adamm00 - credit to @Adamm ###
Check_Lock()
{
	if [ -f "/tmp/$SCRIPT_NAME.lock" ]
	then
		ageoflock="$(($(date +%s) - $(date +%s -r /tmp/$SCRIPT_NAME.lock)))"
		if [ "$ageoflock" -gt 600 ]  #10 minutes#
		then
			Print_Output true "Stale lock file found (>600 seconds old) - purging lock" "$ERR"
			kill "$(sed -n '1p' /tmp/$SCRIPT_NAME.lock)" >/dev/null 2>&1
			Clear_Lock
			echo "$$" > "/tmp/$SCRIPT_NAME.lock"
			return 0
		else
			Print_Output true "Lock file found (age: $ageoflock seconds)" "$ERR"
			if [ $# -eq 0 ] || [ -z "$1" ]
			then
				exit 1
			else
				if [ "$1" = "webui" ]
				then
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

Clear_Lock()
{
	rm -f "/tmp/$SCRIPT_NAME.lock" 2>/dev/null
	return 0
}
############################################################################

### Create "settings" in the custom_settings file, used by the WebUI for version information and script updates ###
### local is the version of the script installed, server is the version on Github ###
##----------------------------------------##
## Modified by Martinski W. [2025-Apr-27] ##
##----------------------------------------##
Set_Version_Custom_Settings()
{
	SETTINGSFILE="/jffs/addons/custom_settings.txt"
	case "$1" in
		local)
			if [ -f "$SETTINGSFILE" ]
			then
				if [ "$(grep -c "^dnvnstat_version_local" "$SETTINGSFILE")" -gt 0 ]
				then
					if [ "$2" != "$(grep "^dnvnstat_version_local" "$SETTINGSFILE" | cut -f2 -d' ')" ]
					then
						sed -i "s/^dnvnstat_version_local.*/dnvnstat_version_local $2/" "$SETTINGSFILE"
					fi
				else
					echo "dnvnstat_version_local $2" >> "$SETTINGSFILE"
				fi
			else
				echo "dnvnstat_version_local $2" >> "$SETTINGSFILE"
			fi
		;;
		server)
			if [ -f "$SETTINGSFILE" ]
			then
				if [ "$(grep -c "^dnvnstat_version_server" "$SETTINGSFILE")" -gt 0 ]
				then
					if [ "$2" != "$(grep "^dnvnstat_version_server" "$SETTINGSFILE" | cut -f2 -d' ')" ]
					then
						sed -i "s/^dnvnstat_version_server.*/dnvnstat_version_server $2/" "$SETTINGSFILE"
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
##----------------------------------------##
## Modified by Martinski W. [2025-Apr-27] ##
##----------------------------------------##
Update_Check()
{
	echo 'var updatestatus = "InProgress";' > "$SCRIPT_WEB_DIR/detect_update.js"
	doupdate="false"
	localver="$(grep "SCRIPT_VERSION=" "/jffs/scripts/$SCRIPT_NAME" | grep -m1 -oE "$scriptVersRegExp")"
	[ -n "$localver" ] && Set_Version_Custom_Settings local "$localver"
	curl -fsL --retry 4 --retry-delay 5 "$SCRIPT_REPO/$SCRIPT_NAME.sh" | grep -qF "de-vnull" || \
	{ Print_Output true "404 error detected - stopping update" "$ERR"; return 1; }
	serverver="$(curl -fsL --retry 4 --retry-delay 5 "$SCRIPT_REPO/$SCRIPT_NAME.sh" | grep "SCRIPT_VERSION=" | grep -m1 -oE "$scriptVersRegExp")"
	if [ "$localver" != "$serverver" ]
	then
		doupdate="version"
		Set_Version_Custom_Settings server "$serverver"
		echo 'var updatestatus = "'"$serverver"'";'  > "$SCRIPT_WEB_DIR/detect_update.js"
	else
		localmd5="$(md5sum "/jffs/scripts/$SCRIPT_NAME" | awk '{print $1}')"
		remotemd5="$(curl -fsL --retry 4 --retry-delay 5 "$SCRIPT_REPO/$SCRIPT_NAME.sh" | md5sum | awk '{print $1}')"
		if [ "$localmd5" != "$remotemd5" ]
		then
			doupdate="md5"
			Set_Version_Custom_Settings server "$serverver-hotfix"
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
##----------------------------------------##
## Modified by Martinski W. [2025-Apr-27] ##
##----------------------------------------##
Update_Version()
{
	if [ $# -eq 0 ] || [ -z "$1" ]
	then
		updatecheckresult="$(Update_Check)"
		isupdate="$(echo "$updatecheckresult" | cut -f1 -d',')"
		localver="$(echo "$updatecheckresult" | cut -f2 -d',')"
		serverver="$(echo "$updatecheckresult" | cut -f3 -d',')"

		if [ "$isupdate" = "version" ]; then
			Print_Output true "New version of $SCRIPT_NAME available - $serverver" "$PASS"
		elif [ "$isupdate" = "md5" ]; then
			Print_Output true "MD5 hash of $SCRIPT_NAME does not match - hotfix available - $serverver" "$PASS"
		fi

		if [ "$isupdate" != "false" ]
		then
			printf "\n${BOLD}Do you want to continue with the update? (y/n)${CLEARFORMAT}  "
			read -r confirm
			case "$confirm" in
				y|Y)
					printf "\n"
					Update_File shared-jy.tar.gz
					Update_File vnstat-ui.asp
					Update_File vnstat.conf
					Update_File S33vnstat
					Download_File "$SCRIPT_REPO/$SCRIPT_NAME.sh" "/jffs/scripts/$SCRIPT_NAME" && \
					Print_Output true "$SCRIPT_NAME successfully updated" "$PASS"
					chmod 0755 "/jffs/scripts/$SCRIPT_NAME"
					Set_Version_Custom_Settings local "$serverver"
					Set_Version_Custom_Settings server "$serverver"
					Clear_Lock
					PressEnter
					exec "$0"
					exit 0
				;;
				*)
					printf "\n"
					Clear_Lock
					return 1
				;;
			esac
		else
			Print_Output true "No updates available - latest is $localver" "$WARN"
			Clear_Lock
		fi
	fi

	if [ "$1" = "force" ]
	then
		serverver="$(curl -fsL --retry 4 --retry-delay 5 "$SCRIPT_REPO/$SCRIPT_NAME.sh" | grep "SCRIPT_VERSION=" | grep -m1 -oE "$scriptVersRegExp")"
		Print_Output true "Downloading latest version ($serverver) of $SCRIPT_NAME" "$PASS"
		Update_File shared-jy.tar.gz
		Update_File vnstat-ui.asp
		Update_File vnstat.conf
		Update_File S33vnstat
		Download_File "$SCRIPT_REPO/$SCRIPT_NAME.sh" "/jffs/scripts/$SCRIPT_NAME" && \
		Print_Output true "$SCRIPT_NAME successfully updated" "$PASS"
		chmod 0755 "/jffs/scripts/$SCRIPT_NAME"
		Set_Version_Custom_Settings local "$serverver"
		Set_Version_Custom_Settings server "$serverver"
		Clear_Lock
		if [ $# -lt 2 ] || [ -z "$2" ]
		then
			PressEnter
			exec "$0"
		elif [ "$2" = "unattended" ]
		then
			exec "$0" postupdate
		fi
		exit 0
	fi
}

Validate_Number()
{
	if [ "$1" -eq "$1" ] 2>/dev/null; then
		return 0
	else
		return 1
	fi
}

Validate_Bandwidth()
{
	if echo "$1" | /bin/grep -oq "^[0-9]*\.\?[0-9]\?[0-9]$"; then
		return 0
	else
		return 1
	fi
}

### Perform relevant actions for secondary files when being updated ###
##----------------------------------------##
## Modified by Martinski W. [2025-Apr-27] ##
##----------------------------------------##
Update_File()
{
	if [ "$1" = "vnstat-ui.asp" ]
	then  ## WebUI page ##
		tmpfile="/tmp/$1"
		if [ -f "$SCRIPT_DIR/$1" ]
		then
			Download_File "$SCRIPT_REPO/$1" "$tmpfile"
			if ! diff -q "$tmpfile" "$SCRIPT_DIR/$1" >/dev/null 2>&1
			then
				Get_WebUI_Page "$SCRIPT_DIR/$1"
				sed -i "\\~$MyWebPage~d" "$TEMP_MENU_TREE"
				rm -f "$SCRIPT_WEBPAGE_DIR/$MyWebPage" 2>/dev/null
				Download_File "$SCRIPT_REPO/$1" "$SCRIPT_DIR/$1"
				Print_Output true "New version of $1 downloaded" "$PASS"
				Mount_WebUI
			fi
			rm -f "$tmpfile"
		else
			Download_File "$SCRIPT_REPO/$1" "$SCRIPT_DIR/$1"
			Print_Output true "New version of $1 downloaded" "$PASS"
			Mount_WebUI
		fi
	elif [ "$1" = "shared-jy.tar.gz" ]
	then  ## shared web resources ##
		if [ ! -f "$SHARED_DIR/${1}.md5" ]
		then
			Download_File "$SHARED_REPO/$1" "$SHARED_DIR/$1"
			Download_File "$SHARED_REPO/${1}.md5" "$SHARED_DIR/${1}.md5"
			tar -xzf "$SHARED_DIR/$1" -C "$SHARED_DIR"
			rm -f "$SHARED_DIR/$1"
			Print_Output true "New version of $1 downloaded" "$PASS"
		else
			localmd5="$(cat "$SHARED_DIR/${1}.md5")"
			remotemd5="$(curl -fsL --retry 4 --retry-delay 5 "$SHARED_REPO/${1}.md5")"
			if [ "$localmd5" != "$remotemd5" ]
			then
				Download_File "$SHARED_REPO/$1" "$SHARED_DIR/$1"
				Download_File "$SHARED_REPO/${1}.md5" "$SHARED_DIR/${1}.md5"
				tar -xzf "$SHARED_DIR/$1" -C "$SHARED_DIR"
				rm -f "$SHARED_DIR/$1"
				Print_Output true "New version of $1 downloaded" "$PASS"
			fi
		fi
	elif [ "$1" = "S33vnstat" ]
	then  ## Entware S script to launch vnstat ##
		tmpfile="/tmp/$1"
		Download_File "$SCRIPT_REPO/$1" "$tmpfile"
		if ! diff -q "$tmpfile" "/opt/etc/init.d/$1" >/dev/null 2>&1
		then
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
	elif [ "$1" = "vnstat.conf" ]
	then  ## vnstat config file ##
		tmpfile="/tmp/$1"
		Download_File "$SCRIPT_REPO/$1" "$tmpfile"
		if [ ! -f "$SCRIPT_STORAGE_DIR/$1" ]
		then
			Download_File "$SCRIPT_REPO/$1" "$SCRIPT_STORAGE_DIR/$1.default"
			Download_File "$SCRIPT_REPO/$1" "$SCRIPT_STORAGE_DIR/$1"
			Print_Output true "$SCRIPT_STORAGE_DIR/$1 does not exist, downloading now." "$PASS"
		elif [ -f "$SCRIPT_STORAGE_DIR/$1.default" ]
		then
			if ! diff -q "$tmpfile" "$SCRIPT_STORAGE_DIR/$1.default" >/dev/null 2>&1; then
				Download_File "$SCRIPT_REPO/$1" "$SCRIPT_STORAGE_DIR/$1.default"
				Print_Output true "New default version of $1 downloaded to $SCRIPT_STORAGE_DIR/$1.default, please compare against your $SCRIPT_STORAGE_DIR/$1" "$PASS"
			fi
		else
			Download_File "$SCRIPT_REPO/$1" "$SCRIPT_STORAGE_DIR/$1.default"
			Print_Output true "$SCRIPT_STORAGE_DIR/$1.default does not exist, downloading now. Please compare against your $SCRIPT_STORAGE_DIR/$1" "$PASS"
		fi
		rm -f "$tmpfile"
	else
		return 1
	fi
}

##----------------------------------------##
## Modified by Martinski W. [2025-Apr-27] ##
##----------------------------------------##
Conf_FromSettings()
{
	SETTINGSFILE="/jffs/addons/custom_settings.txt"
	TMPFILE="/tmp/dnvnstat_settings.txt"

	if [ -f "$SETTINGSFILE" ]
	then
		if [ "$(grep "^dnvnstat_" $SETTINGSFILE | grep -v "version" -c)" -gt 0 ]
		then
			Print_Output true "Updated settings from WebUI found, merging into $SCRIPT_CONF..." "$PASS"
			cp -a "$SCRIPT_CONF" "${SCRIPT_CONF}.bak"
			cp -a "$VNSTAT_CONFIG" "${VNSTAT_CONFIG}.bak"
			grep "^dnvnstat_" "$SETTINGSFILE" | grep -v "version" > "$TMPFILE"
			sed -i "s/^dnvnstat_//g;s/ /=/g" "$TMPFILE"
			warningresetrequired="false"
			while IFS='' read -r line || [ -n "$line" ]
			do
				SETTINGNAME="$(echo "$line" | cut -f1 -d'=' | awk '{ print toupper($1) }')"
				SETTINGVALUE="$(echo "$line" | cut -f2 -d'=')"
				if [ "$SETTINGNAME" != "MONTHROTATE" ]
				then
					if [ "$SETTINGNAME" = "DATAALLOWANCE" ]
					then
						if [ "$(echo "$SETTINGVALUE $(BandwidthAllowance check)" | awk '{print ($1 != $2)}')" -eq 1 ]
						then
							warningresetrequired="true"
						fi
					fi
					sed -i "s/$SETTINGNAME=.*/$SETTINGNAME=$SETTINGVALUE/" "$SCRIPT_CONF"
				elif [ "$SETTINGNAME" = "MONTHROTATE" ]
				then
					if [ "$SETTINGVALUE" != "$(AllowanceStartDay check)" ]
					then
						warningresetrequired="true"
					fi
					sed -i 's/^MonthRotate .*$/MonthRotate '"$SETTINGVALUE"'/' "$VNSTAT_CONFIG"
				fi
			done < "$TMPFILE"

			grep '^dnvnstat_version' "$SETTINGSFILE" > "$TMPFILE"
			sed -i "\\~dnvnstat_~d" "$SETTINGSFILE"
			mv -f "$SETTINGSFILE" "${SETTINGSFILE}.bak"
			cat "${SETTINGSFILE}.bak" "$TMPFILE" > "$SETTINGSFILE"
			rm -f "$TMPFILE"
			rm -f "${SETTINGSFILE}.bak"

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
##----------------------------------------##
## Modified by Martinski W. [2025-Apr-27] ##
##----------------------------------------##
Create_Dirs()
{
	if [ ! -d "$SCRIPT_DIR" ]; then
		mkdir -p "$SCRIPT_DIR"
	fi

	if [ ! -d "$SCRIPT_STORAGE_DIR" ]; then
		mkdir -p "$SCRIPT_STORAGE_DIR"
	fi

	if [ ! -d "$IMAGE_OUTPUT_DIR" ]; then
		mkdir -p "$IMAGE_OUTPUT_DIR"
	fi

	if [ ! -d "$CSV_OUTPUT_DIR" ]; then
		mkdir -p "$CSV_OUTPUT_DIR"
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

	if [ ! -d "$SHARE_TEMP_DIR" ]
	then
		mkdir -m 777 -p "$SHARE_TEMP_DIR"
		export SQLITE_TMPDIR TMPDIR
	fi
}

### Create symbolic links to /www/user for WebUI files to avoid file duplication ###
Create_Symlinks()
{
	rm -rf "${SCRIPT_WEB_DIR:?}/"* 2>/dev/null

	ln -s /tmp/detect_vnstat.js "$SCRIPT_WEB_DIR/detect_vnstat.js" 2>/dev/null
	ln -s "$SCRIPT_STORAGE_DIR/.vnstatusage" "$SCRIPT_WEB_DIR/vnstatusage.js" 2>/dev/null
	ln -s "$VNSTAT_OUTPUT_FILE" "$SCRIPT_WEB_DIR/vnstatoutput.htm" 2>/dev/null
	ln -s "$SCRIPT_CONF" "$SCRIPT_WEB_DIR/config.htm" 2>/dev/null
	ln -s "$VNSTAT_CONFIG" "$SCRIPT_WEB_DIR/vnstatconf.htm" 2>/dev/null
	ln -s "$IMAGE_OUTPUT_DIR" "$SCRIPT_WEB_DIR/images" 2>/dev/null
	ln -s "$CSV_OUTPUT_DIR" "$SCRIPT_WEB_DIR/csv" 2>/dev/null

	if [ ! -d "$SHARED_WEB_DIR" ]; then
		ln -s "$SHARED_DIR" "$SHARED_WEB_DIR" 2>/dev/null
	fi
}

##----------------------------------------##
## Modified by Martinski W. [2025-Apr-27] ##
##----------------------------------------##
Conf_Exists()
{
	local restartvnstat=false

	if [ -f "$VNSTAT_CONFIG" ]
	then
		restartvnstat=false
		if ! grep -q "^MaxBandwidth 1000" "$VNSTAT_CONFIG"; then
			sed -i 's/^MaxBandwidth.*$/MaxBandwidth 1000/' "$VNSTAT_CONFIG"
			restartvnstat=true
		fi
		if ! grep -q "^TimeSyncWait 10" "$VNSTAT_CONFIG"; then
			sed -i 's/^TimeSyncWait.*$/TimeSyncWait 10/' "$VNSTAT_CONFIG"
			restartvnstat=true
		fi
		if ! grep -q "^UpdateInterval 30" "$VNSTAT_CONFIG"; then
			sed -i 's/^UpdateInterval.*$/UpdateInterval 30/' "$VNSTAT_CONFIG"
			restartvnstat=true
		fi
		if ! grep -q "^UnitMode 2" "$VNSTAT_CONFIG"; then
			sed -i 's/^UnitMode.*$/UnitMode 2/' "$VNSTAT_CONFIG"
			restartvnstat=true
		fi
		if ! grep -q "^RateUnitMode 1" "$VNSTAT_CONFIG"; then
			sed -i 's/^RateUnitMode.*$/RateUnitMode 1/' "$VNSTAT_CONFIG"
			restartvnstat=true
		fi
		if ! grep -q "^OutputStyle 0" "$VNSTAT_CONFIG"; then
			sed -i 's/^OutputStyle.*$/OutputStyle 0/' "$VNSTAT_CONFIG"
			restartvnstat=true
		fi
		if ! grep -q '^MonthFormat "%Y-%m"' "$VNSTAT_CONFIG"; then
			sed -i 's/^MonthFormat.*$/MonthFormat "%Y-%m"/' "$VNSTAT_CONFIG"
			restartvnstat=true
		fi

		if [ "$restartvnstat" = "true" ]
		then
			/opt/etc/init.d/S33vnstat restart >/dev/null 2>&1
			Generate_Images silent
			Generate_Stats silent
			Check_Bandwidth_Usage silent
		fi
	else
		Update_File vnstat.conf
	fi

	if [ -f "$SCRIPT_CONF" ]
	then
		dos2unix "$SCRIPT_CONF"
		chmod 0644 "$SCRIPT_CONF"
		sed -i -e 's/"//g' "$SCRIPT_CONF"
		if ! grep -q "^DAILYEMAIL=" "$SCRIPT_CONF"; then
			echo "DAILYEMAIL=none" >> "$SCRIPT_CONF"
		fi
		if ! grep -q "^USAGEEMAIL=" "$SCRIPT_CONF"; then
			echo "USAGEEMAIL=false" >> "$SCRIPT_CONF"
		fi
		if ! grep -q "^DATAALLOWANCE=" "$SCRIPT_CONF"; then
			echo "DATAALLOWANCE=1200.00" >> "$SCRIPT_CONF"
		fi
		if ! grep -q "^ALLOWANCEUNIT=" "$SCRIPT_CONF"; then
			echo "ALLOWANCEUNIT=G" >> "$SCRIPT_CONF"
		fi
		if ! grep -q "^STORAGELOCATION=" "$SCRIPT_CONF"; then
			echo "STORAGELOCATION=jffs" >> "$SCRIPT_CONF"
		fi
		if ! grep -q "^OUTPUTTIMEMODE=" "$SCRIPT_CONF"; then
			echo "OUTPUTTIMEMODE=unix" >> "$SCRIPT_CONF"
		fi
		return 0
	else
		{ echo "DAILYEMAIL=none"; echo "USAGEEMAIL=false"; echo "DATAALLOWANCE=1200.00"
		  echo "ALLOWANCEUNIT=G"; echo "STORAGELOCATION=jffs"; echo "OUTPUTTIMEMODE=unix"
		} > "$SCRIPT_CONF"
		return 1
	fi
}

### Add script hook to service-event and pass service_event argument and all other arguments passed to the service call ###
Auto_ServiceEvent()
{
	case $1 in
		create)
			if [ -f /jffs/scripts/service-event ]; then
				STARTUPLINECOUNT=$(grep -c '# '"$SCRIPT_NAME" /jffs/scripts/service-event)
				STARTUPLINECOUNTEX=$(grep -cx "/jffs/scripts/$SCRIPT_NAME service_event"' "$@" & # '"$SCRIPT_NAME" /jffs/scripts/service-event)
				
				if [ "$STARTUPLINECOUNT" -gt 1 ] || { [ "$STARTUPLINECOUNTEX" -eq 0 ] && [ "$STARTUPLINECOUNT" -gt 0 ]; }; then
					sed -i -e '/# '"$SCRIPT_NAME"'/d' /jffs/scripts/service-event
				fi
				
				if [ "$STARTUPLINECOUNTEX" -eq 0 ]; then
					echo "/jffs/scripts/$SCRIPT_NAME service_event"' "$@" & # '"$SCRIPT_NAME" >> /jffs/scripts/service-event
				fi
			else
				echo "#!/bin/sh" > /jffs/scripts/service-event
				echo "" >> /jffs/scripts/service-event
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

##----------------------------------------##
## Modified by Martinski W. [2025-Apr-27] ##
##----------------------------------------##
Download_File()
{ /usr/sbin/curl -LSs --retry 4 --retry-delay 5 --retry-connrefused "$1" -o "$2" ; }

##-------------------------------------##
## Added by Martinski W. [2025-Apr-27] ##
##-------------------------------------##
_Check_WebGUI_Page_Exists_()
{
   local webPageStr  webPageFile  theWebPage

   if [ ! -f "$TEMP_MENU_TREE" ]
   then echo "NONE" ; return 1 ; fi

   theWebPage="NONE"
   webPageStr="$(grep -E -m1 "^$webPageLineRegExp" "$TEMP_MENU_TREE")"
   if [ -n "$webPageStr" ]
   then
       webPageFile="$(echo "$webPageStr" | grep -owE "$webPageFileRegExp" | head -n1)"
       if [ -n "$webPageFile" ] && [ -s "${SCRIPT_WEBPAGE_DIR}/$webPageFile" ]
       then theWebPage="$webPageFile" ; fi
   fi
   echo "$theWebPage"
}

##----------------------------------------##
## Modified by Martinski W. [2025-Apr-27] ##
##----------------------------------------##
Get_WebUI_Page()
{
	local webPageFile  webPagePath

	MyWebPage="$(_Check_WebGUI_Page_Exists_)"

	for indx in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20
	do
		webPageFile="user${indx}.asp"
		webPagePath="${SCRIPT_WEBPAGE_DIR}/$webPageFile"

		if [ -s "$webPagePath" ] && \
		   [ "$(md5sum < "$1")" = "$(md5sum < "$webPagePath")" ]
		then
			MyWebPage="$webPageFile"
			break
		elif [ "$MyWebPage" = "NONE" ] && [ ! -s "$webPagePath" ]
		then
			MyWebPage="$webPageFile"
		fi
	done
}

### function based on @dave14305's FlexQoS webconfigpage function ###
##----------------------------------------##
## Modified by Martinski W. [2025-Apr-27] ##
##----------------------------------------##
Get_WebUI_URL()
{
	local urlPage  urlProto  urlDomain  urlPort  lanPort

	if [ ! -f "$TEMP_MENU_TREE" ]
	then
		echo "**ERROR**: WebUI page NOT mounted"
		return 1
	fi

	urlPage="$(sed -nE "/$SCRIPT_NAME/ s/.*url\: \"(user[0-9]+\.asp)\".*/\1/p" "$TEMP_MENU_TREE")"

	if [ "$(nvram get http_enable)" -eq 1 ]; then
		urlProto="https"
	else
		urlProto="http"
	fi
	if [ -n "$(nvram get lan_domain)" ]; then
		urlDomain="$(nvram get lan_hostname).$(nvram get lan_domain)"
	else
		urlDomain="$(nvram get lan_ipaddr)"
	fi

	lanPort="$(nvram get ${urlProto}_lanport)"
	if [ "$lanPort" -eq 80 ] || [ "$lanPort" -eq 443 ]
	then
		urlPort=""
	else
		urlPort=":$lanPort"
	fi

	if echo "$urlPage" | grep -qE "^${webPageFileRegExp}$" && \
	   [ -s "${SCRIPT_WEBPAGE_DIR}/$urlPage" ]
	then
		echo "${urlProto}://${urlDomain}${urlPort}/${urlPage}" | tr "A-Z" "a-z"
	else
		echo "**ERROR**: WebUI page NOT found"
	fi
}

##-------------------------------------##
## Added by Martinski W. [2025-Apr-27] ##
##-------------------------------------##
_CreateMenuAddOnsSection_()
{
   if grep -qE "^${webPageMenuAddons}$" "$TEMP_MENU_TREE" && \
      grep -qE "${webPageHelpSupprt}$" "$TEMP_MENU_TREE"
   then return 0 ; fi

   lineinsBefore="$(($(grep -n "^exclude:" "$TEMP_MENU_TREE" | cut -f1 -d':') - 1))"

   sed -i "$lineinsBefore""i\
${BEGIN_MenuAddOnsTag}\n\
,\n{\n\
${webPageMenuAddons}\n\
index: \"menu_Addons\",\n\
tab: [\n\
{url: \"javascript:var helpwindow=window.open('\/ext\/shared-jy\/redirect.htm')\", ${webPageHelpSupprt}\n\
{url: \"NULL\", tabName: \"__INHERIT__\"}\n\
]\n}\n\
${ENDIN_MenuAddOnsTag}" "$TEMP_MENU_TREE"
}

### locking mechanism code credit to Martineau (@MartineauUK) ###
##----------------------------------------##
## Modified by Martinski W. [2025-Apr-27] ##
##----------------------------------------##
Mount_WebUI()
{
	Print_Output true "Mounting WebUI tab for $SCRIPT_NAME" "$PASS"
	LOCKFILE=/tmp/addonwebui.lock
	FD=386
	eval exec "$FD>$LOCKFILE"
	flock -x "$FD"
	Get_WebUI_Page "$SCRIPT_DIR/vnstat-ui.asp"
	if [ "$MyWebPage" = "NONE" ]
	then
		Print_Output true "**ERROR** Unable to mount $SCRIPT_NAME WebUI page, exiting" "$CRIT"
		flock -u "$FD"
		return 1
	fi
	cp -fp "$SCRIPT_DIR/vnstat-ui.asp" "$SCRIPT_WEBPAGE_DIR/$MyWebPage"
	echo "$SCRIPT_NAME" > "$SCRIPT_WEBPAGE_DIR/$(echo "$MyWebPage" | cut -f1 -d'.').title"

	if [ "$(uname -o)" = "ASUSWRT-Merlin" ]
	then
		if [ ! -f /tmp/index_style.css ]; then
			cp -fp /www/index_style.css /tmp/
		fi

		if ! grep -q '.menu_Addons' /tmp/index_style.css
		then
			echo ".menu_Addons { background: url(ext/shared-jy/addons.png); }" >> /tmp/index_style.css
		fi

		umount /www/index_style.css 2>/dev/null
		mount -o bind /tmp/index_style.css /www/index_style.css

		if [ ! -f "$TEMP_MENU_TREE" ]; then
			cp -fp /www/require/modules/menuTree.js "$TEMP_MENU_TREE"
		fi
		sed -i "\\~$MyWebPage~d" "$TEMP_MENU_TREE"

		_CreateMenuAddOnsSection_

		sed -i "/url: \"javascript:var helpwindow=window.open('\/ext\/shared-jy\/redirect.htm'/i {url: \"$MyWebPage\", tabName: \"$SCRIPT_NAME\"}," "$TEMP_MENU_TREE"

		umount /www/require/modules/menuTree.js 2>/dev/null
		mount -o bind "$TEMP_MENU_TREE" /www/require/modules/menuTree.js
	fi
	flock -u "$FD"
	Print_Output true "Mounted $SCRIPT_NAME WebUI page as $MyWebPage" "$PASS"
}

##-------------------------------------##
## Added by Martinski W. [2025-Apr-27] ##
##-------------------------------------##
_CheckFor_WebGUI_Page_()
{
   if [ "$(_Check_WebGUI_Page_Exists_)" = "NONE" ]
   then Mount_WebUI ; fi
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

PressEnter()
{
	while true
	do
		printf "Press <Enter> key to continue..."
		read -rs key
		case "$key" in
			*) break ;;
		esac
	done
	return 0
}

Check_Requirements()
{
	CHECKSFAILED="false"

	if [ "$(nvram get jffs2_scripts)" -ne 1 ]; then
		nvram set jffs2_scripts=1
		nvram commit
		Print_Output true "Custom JFFS Scripts enabled" "$WARN"
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

	if [ "$CHECKSFAILED" = "false" ]
	then
		Print_Output false "Installing required packages from Entware" "$PASS"
		opkg update
		opkg install vnstat2
		opkg install vnstati2
		opkg install libjpeg-turbo >/dev/null 2>&1
		opkg install jq
		opkg install sqlite3-cli
		opkg install p7zip
		opkg install findutils
		rm -f /opt/etc/vnstat.conf
		return 0
	else
		return 1
	fi
}

### Determine WAN interface using nvram ###
##----------------------------------------##
## Modified by Martinski W. [2025-Apr-29] ##
##----------------------------------------##
Get_WAN_IFace()
{
    local wanPrefix=""  wanProto
    for ifaceNum in 0 1
    do
        if [ "$(nvram get "wan${ifaceNum}_primary")" = "1" ]
        then wanPrefix="wan${ifaceNum}" ; break
        fi
    done
    if [ -z "$wanPrefix" ] ; then echo "ERROR" ; return 1
    fi

    wanProto="$(nvram get "${wanPrefix}_proto")"
    if [ "$wanProto" = "pptp" ] || \
       [ "$wanProto" = "l2tp" ] || \
       [ "$wanProto" = "pppoe" ]
    then
        IFACE_WAN="$(nvram get "${wanPrefix}_pppoe_ifname")"
    else
        IFACE_WAN="$(nvram get "${wanPrefix}_ifname")"
    fi
    echo "$IFACE_WAN"
    return 0
}

##----------------------------------------##
## Modified by Martinski W. [2025-Apr-27] ##
##----------------------------------------##
ScriptStorageLocation()
{
	case "$1" in
		usb)
			printf "Please wait..."
			sed -i 's/^STORAGELOCATION.*$/STORAGELOCATION=usb/' "$SCRIPT_CONF"
			mkdir -p "/opt/share/$SCRIPT_NAME.d/"
			mv -f "/jffs/addons/$SCRIPT_NAME.d/csv" "/opt/share/$SCRIPT_NAME.d/" 2>/dev/null
			mv -f "/jffs/addons/$SCRIPT_NAME.d/images" "/opt/share/$SCRIPT_NAME.d/" 2>/dev/null
			mv -f "/jffs/addons/$SCRIPT_NAME.d/config" "/opt/share/$SCRIPT_NAME.d/" 2>/dev/null
			mv -f "/jffs/addons/$SCRIPT_NAME.d/config.bak" "/opt/share/$SCRIPT_NAME.d/" 2>/dev/null
			mv -f "/jffs/addons/$SCRIPT_NAME.d/vnstat.conf" "/opt/share/$SCRIPT_NAME.d/" 2>/dev/null
			mv -f "/jffs/addons/$SCRIPT_NAME.d/vnstat.conf.bak" "/opt/share/$SCRIPT_NAME.d/" 2>/dev/null
			mv -f "/jffs/addons/$SCRIPT_NAME.d/vnstat.conf.default" "/opt/share/$SCRIPT_NAME.d/" 2>/dev/null
			mv -f "/jffs/addons/$SCRIPT_NAME.d/.vnstatusage" "/opt/share/$SCRIPT_NAME.d/" 2>/dev/null
			mv -f "/jffs/addons/$SCRIPT_NAME.d/vnstat.txt" "/opt/share/$SCRIPT_NAME.d/" 2>/dev/null
			mv -f "/jffs/addons/$SCRIPT_NAME.d/.v2upgraded" "/opt/share/$SCRIPT_NAME.d/" 2>/dev/null
			mv -f "/jffs/addons/$SCRIPT_NAME.d/v1" "/opt/share/$SCRIPT_NAME.d/" 2>/dev/null
			SCRIPT_CONF="/opt/share/$SCRIPT_NAME.d/config"
			VNSTAT_CONFIG="/opt/share/$SCRIPT_NAME.d/vnstat.conf"
			/opt/etc/init.d/S33vnstat restart >/dev/null 2>&1
			ScriptStorageLocation load
			sleep 1
		;;
		jffs)
			printf "Please wait..."
			sed -i 's/^STORAGELOCATION.*$/STORAGELOCATION=jffs/' "$SCRIPT_CONF"
			mkdir -p "/jffs/addons/$SCRIPT_NAME.d/"
			mv -f "/opt/share/$SCRIPT_NAME.d/csv" "/jffs/addons/$SCRIPT_NAME.d/" 2>/dev/null
			mv -f "/opt/share/$SCRIPT_NAME.d/images" "/jffs/addons/$SCRIPT_NAME.d/" 2>/dev/null
			mv -f "/opt/share/$SCRIPT_NAME.d/config" "/jffs/addons/$SCRIPT_NAME.d/" 2>/dev/null
			mv -f "/opt/share/$SCRIPT_NAME.d/config.bak" "/jffs/addons/$SCRIPT_NAME.d/" 2>/dev/null
			mv -f "/opt/share/$SCRIPT_NAME.d/vnstat.conf" "/jffs/addons/$SCRIPT_NAME.d/" 2>/dev/null
			mv -f "/opt/share/$SCRIPT_NAME.d/vnstat.conf.bak" "/jffs/addons/$SCRIPT_NAME.d/" 2>/dev/null
			mv -f "/opt/share/$SCRIPT_NAME.d/vnstat.conf.default" "/jffs/addons/$SCRIPT_NAME.d/" 2>/dev/null
			mv -f "/opt/share/$SCRIPT_NAME.d/.vnstatusage" "/jffs/addons/$SCRIPT_NAME.d/" 2>/dev/null
			mv -f "/opt/share/$SCRIPT_NAME.d/vnstat.txt" "/jffs/addons/$SCRIPT_NAME.d/" 2>/dev/null
			mv -f "/opt/share/$SCRIPT_NAME.d/.v2upgraded" "/jffs/addons/$SCRIPT_NAME.d/" 2>/dev/null
			mv -f "/opt/share/$SCRIPT_NAME.d/v1" "/jffs/addons/$SCRIPT_NAME.d/" 2>/dev/null
			SCRIPT_CONF="/jffs/addons/$SCRIPT_NAME.d/config"
			VNSTAT_CONFIG="/jffs/addons/$SCRIPT_NAME.d/vnstat.conf"
			/opt/etc/init.d/S33vnstat restart >/dev/null 2>&1
			ScriptStorageLocation load
			sleep 1
		;;
		check)
			STORAGELOCATION="$(grep "^STORAGELOCATION=" "$SCRIPT_CONF" | cut -f2 -d"=")"
			echo "${STORAGELOCATION:=jffs}"
		;;
		load)
			STORAGELOCATION="$(ScriptStorageLocation check)"
			if [ "$STORAGELOCATION" = "usb" ]
			then
				SCRIPT_STORAGE_DIR="/opt/share/$SCRIPT_NAME.d"
			elif [ "$STORAGELOCATION" = "jffs" ]
			then
				SCRIPT_STORAGE_DIR="/jffs/addons/$SCRIPT_NAME.d"
			fi
			chmod 777 "$SCRIPT_STORAGE_DIR"
			CSV_OUTPUT_DIR="$SCRIPT_STORAGE_DIR/csv"
			IMAGE_OUTPUT_DIR="$SCRIPT_STORAGE_DIR/images"
			VNSTAT_COMMAND="vnstat --config $VNSTAT_CONFIG"
			VNSTATI_COMMAND="vnstati --config $VNSTAT_CONFIG"
			VNSTAT_OUTPUT_FILE="$SCRIPT_STORAGE_DIR/vnstat.txt"
		;;
	esac
}

OutputTimeMode()
{
	case "$1" in
		unix)
			sed -i 's/^OUTPUTTIMEMODE.*$/OUTPUTTIMEMODE=unix/' "$SCRIPT_CONF"
			Generate_CSVs
		;;
		non-unix)
			sed -i 's/^OUTPUTTIMEMODE.*$/OUTPUTTIMEMODE=non-unix/' "$SCRIPT_CONF"
			Generate_CSVs
		;;
		check)
			OUTPUTTIMEMODE="$(grep "^OUTPUTTIMEMODE=" "$SCRIPT_CONF" | cut -f2 -d"=")"
			echo "${OUTPUTTIMEMODE:=unix}"
		;;
	esac
}

##-------------------------------------##
## Added by Martinski W. [2025-Apr-28] ##
##-------------------------------------##
_GetFileSize_()
{
   local sizeUnits  sizeInfo  fileSize
   if [ $# -eq 0 ] || [ -z "$1" ] || [ ! -s "$1" ]
   then echo 0; return 1 ; fi

   if [ $# -lt 2 ] || [ -z "$2" ] || \
      ! echo "$2" | grep -qE "^(B|KB|MB|GB|HR|HRx)$"
   then sizeUnits="B" ; else sizeUnits="$2" ; fi

   _GetNum_() { printf "%.1f" "$(echo "$1" | awk "{print $1}")" ; }

   case "$sizeUnits" in
       B|KB|MB|GB)
           fileSize="$(ls -1l "$1" | awk -F ' ' '{print $3}')"
           case "$sizeUnits" in
               KB) fileSize="$(_GetNum_ "($fileSize / $oneKByte)")" ;;
               MB) fileSize="$(_GetNum_ "($fileSize / $oneMByte)")" ;;
               GB) fileSize="$(_GetNum_ "($fileSize / $oneGByte)")" ;;
           esac
           echo "$fileSize"
           ;;
       HR|HRx)
           fileSize="$(ls -1lh "$1" | awk -F ' ' '{print $3}')"
           sizeInfo="${fileSize}B"
           if [ "$sizeUnits" = "HR" ]
           then echo "$sizeInfo" ; return 0 ; fi
           sizeUnits="$(echo "$sizeInfo" | tr -d '.0-9')"
           case "$sizeUnits" in
               MB) fileSize="$(_GetFileSize_ "$1" KB)"
                   sizeInfo="$sizeInfo [${fileSize}KB]"
                   ;;
               GB) fileSize="$(_GetFileSize_ "$1" MB)"
                   sizeInfo="$sizeInfo [${fileSize}MB]"
                   ;;
           esac
           echo "$sizeInfo"
           ;;
       *) echo 0 ;;
   esac
   return 0
}

##-------------------------------------##
## Added by Martinski W. [2025-Apr-28] ##
##-------------------------------------##
_GetVNStatDatabaseFilePath_()
{
    local dbaseDirPath
    if [ ! -s "$VNSTAT_CONFIG" ] ; then echo ; return 1 ; fi
    dbaseDirPath="$(grep '^DatabaseDir ' "$VNSTAT_CONFIG" | awk -F ' ' '{print $2}' | sed 's/"//g')"
    echo "${dbaseDirPath}/vnstat.db"
    return 0
}

##-------------------------------------##
## Added by Martinski W. [2025-Apr-27] ##
##-------------------------------------##
_GetInterfaceNameFromConfig_()
{
    local iFaceName
    if [ ! -s "$VNSTAT_CONFIG" ] ; then echo ; return 1 ; fi
    iFaceName="$(grep '^Interface ' "$VNSTAT_CONFIG" | awk -F ' ' '{print $2}' | sed 's/"//g')"
    echo "$iFaceName"
    return 0
}

##----------------------------------------##
## Modified by Martinski W. [2025-Apr-28] ##
##----------------------------------------##
Generate_CSVs()
{
	interface="$(_GetInterfaceNameFromConfig_)"
	VNSTAT_DBASE="$(_GetVNStatDatabaseFilePath_)"
	if [ -z "$interface" ] || [ -z "$VNSTAT_DBASE" ] || [ ! -f "$VNSTAT_DBASE" ]
	then
		Print_Output true "**ERROR** Unable to generate CSVs" "$CRIT"
		return 1
	fi
	renice 15 $$
	TZ=$(cat /etc/TZ)
	export TZ

	timenow=$(date +"%s")

	{
		echo ".headers off"
		echo ".output /tmp/dn-vnstatiface"
		echo "SELECT id FROM [interface] WHERE [name] = '$interface';"
	} > /tmp/dn-vnstat.sql
	"$SQLITE3_PATH" "$VNSTAT_DBASE" < /tmp/dn-vnstat.sql
	interfaceid="$(cat /tmp/dn-vnstatiface)"
	rm -f /tmp/dn-vnstatiface

	intervallist="fiveminute hour day"

	for interval in $intervallist
	do
		metriclist="rx tx"

		for metric in $metriclist
		do
			{
				echo ".mode csv"
				echo ".headers off"
				echo ".output $CSV_OUTPUT_DIR/${metric}daily.tmp"
				echo "SELECT '$metric' Metric,strftime('%s',[date],'utc') Time,[$metric] Value FROM $interval WHERE [interface] = '$interfaceid' AND strftime('%s',[date],'utc') >= strftime('%s',datetime($timenow,'unixepoch','-1 day'));"
			} > /tmp/dn-vnstat.sql
			"$SQLITE3_PATH" "$VNSTAT_DBASE" < /tmp/dn-vnstat.sql

			{
				echo ".mode csv"
				echo ".headers off"
				echo ".output $CSV_OUTPUT_DIR/${metric}weekly.tmp"
				echo "SELECT '$metric' Metric,strftime('%s',[date],'utc') Time,[$metric] Value FROM $interval WHERE [interface] = '$interfaceid' AND strftime('%s',[date],'utc') >= strftime('%s',datetime($timenow,'unixepoch','-7 day'));"
			} > /tmp/dn-vnstat.sql
			"$SQLITE3_PATH" "$VNSTAT_DBASE" < /tmp/dn-vnstat.sql

			{
				echo ".mode csv"
				echo ".headers off"
				echo ".output $CSV_OUTPUT_DIR/${metric}monthly.tmp"
				echo "SELECT '$metric' Metric,strftime('%s',[date],'utc') Time,[$metric] Value FROM $interval WHERE [interface] = '$interfaceid' AND strftime('%s',[date],'utc') >= strftime('%s',datetime($timenow,'unixepoch','-30 day'));"
			} > /tmp/dn-vnstat.sql
			"$SQLITE3_PATH" "$VNSTAT_DBASE" < /tmp/dn-vnstat.sql

			rm -f /tmp/dn-vnstat.sql
		done

		cat "$CSV_OUTPUT_DIR/rxdaily.tmp" "$CSV_OUTPUT_DIR/txdaily.tmp" > "$CSV_OUTPUT_DIR/DataUsage_${interval}_daily.htm" 2> /dev/null
		cat "$CSV_OUTPUT_DIR/rxweekly.tmp" "$CSV_OUTPUT_DIR/txweekly.tmp" > "$CSV_OUTPUT_DIR/DataUsage_${interval}_weekly.htm" 2> /dev/null
		cat "$CSV_OUTPUT_DIR/rxmonthly.tmp" "$CSV_OUTPUT_DIR/txmonthly.tmp" > "$CSV_OUTPUT_DIR/DataUsage_${interval}_monthly.htm" 2> /dev/null

		sed -i 's/rx/Received/g;s/tx/Sent/g;1i Metric,Time,Value' "$CSV_OUTPUT_DIR/DataUsage_${interval}_daily.htm"
		sed -i 's/rx/Received/g;s/tx/Sent/g;1i Metric,Time,Value' "$CSV_OUTPUT_DIR/DataUsage_${interval}_weekly.htm"
		sed -i 's/rx/Received/g;s/tx/Sent/g;1i Metric,Time,Value' "$CSV_OUTPUT_DIR/DataUsage_${interval}_monthly.htm"

		rm -f "$CSV_OUTPUT_DIR/rx"*
		rm -f "$CSV_OUTPUT_DIR/tx"*
	done

	metriclist="rx tx"

	for metric in $metriclist
	do
		{
			echo ".mode csv"
			echo ".headers off"
			echo ".output $CSV_OUTPUT_DIR/week_this_${metric}.tmp"
			echo "SELECT '$metric' Metric,strftime('%w', [date]) Time,[$metric] Value FROM day WHERE [interface] = '$interfaceid' AND strftime('%s',[date],'utc') >= strftime('%s',datetime($timenow,'unixepoch','start of day','+1 day','-7 day'));"
		} > /tmp/dn-vnstat.sql
		"$SQLITE3_PATH" "$VNSTAT_DBASE" < /tmp/dn-vnstat.sql

		{
			echo ".mode csv"
			echo ".headers off"
			echo ".output $CSV_OUTPUT_DIR/week_prev_${metric}.tmp"
			echo "SELECT '$metric' Metric,strftime('%w', [date]) Time,[$metric] Value FROM day WHERE [interface] = '$interfaceid' AND strftime('%s',[date],'utc') < strftime('%s',datetime($timenow,'unixepoch','start of day','+1 day','-7 day')) AND strftime('%s',[date],'utc') >= strftime('%s',datetime($timenow,'unixepoch','start of day','+1 day','-14 day'));"
		} > /tmp/dn-vnstat.sql
		"$SQLITE3_PATH" "$VNSTAT_DBASE" < /tmp/dn-vnstat.sql

		{
			echo ".mode csv"
			echo ".headers off"
			echo ".output $CSV_OUTPUT_DIR/week_summary_this_${metric}.tmp"
			echo "SELECT '$metric' Metric,'Current 7 days' Time,IFNULL(SUM([$metric]),'0') Value FROM day WHERE [interface] = '$interfaceid' AND strftime('%s',[date],'utc') >= strftime('%s',datetime($timenow,'unixepoch','start of day','+1 day','-7 day'));"
		} > /tmp/dn-vnstat.sql
		"$SQLITE3_PATH" "$VNSTAT_DBASE" < /tmp/dn-vnstat.sql

		{
			echo ".mode csv"
			echo ".headers off"
			echo ".output $CSV_OUTPUT_DIR/week_summary_prev_${metric}.tmp"
			echo "SELECT '$metric' Metric,'Previous 7 days' Time,IFNULL(SUM([$metric]),'0') Value FROM day WHERE [interface] = '$interfaceid' AND strftime('%s',[date],'utc') < strftime('%s',datetime($timenow,'unixepoch','start of day','+1 day','-7 day')) AND strftime('%s',[date],'utc') >= strftime('%s',datetime($timenow,'unixepoch','start of day','+1 day','-14 day'));"
		} > /tmp/dn-vnstat.sql
		"$SQLITE3_PATH" "$VNSTAT_DBASE" < /tmp/dn-vnstat.sql

		{
			echo ".mode csv"
			echo ".headers off"
			echo ".output $CSV_OUTPUT_DIR/week_summary_prev2_${metric}.tmp"
			echo "SELECT '$metric' Metric,'2 weeks ago' Time,IFNULL(SUM([$metric]),'0') Value FROM day WHERE [interface] = '$interfaceid' AND strftime('%s',[date],'utc') < strftime('%s',datetime($timenow,'unixepoch','start of day','+1 day','-14 day')) AND strftime('%s',[date],'utc') >= strftime('%s',datetime($timenow,'unixepoch','start of day','+1 day','-21 day'));"
		} > /tmp/dn-vnstat.sql
		"$SQLITE3_PATH" "$VNSTAT_DBASE" < /tmp/dn-vnstat.sql
	done

	cat "$CSV_OUTPUT_DIR/week_this_rx.tmp" "$CSV_OUTPUT_DIR/week_this_tx.tmp" > "$CSV_OUTPUT_DIR/WeekThis.htm" 2> /dev/null
	cat "$CSV_OUTPUT_DIR/week_prev_rx.tmp" "$CSV_OUTPUT_DIR/week_prev_tx.tmp" > "$CSV_OUTPUT_DIR/WeekPrev.htm" 2> /dev/null

	sed -i 's/rx/Received/g;s/tx/Sent/g;1i Metric,Time,Value' "$CSV_OUTPUT_DIR/WeekThis.htm"
	sed -i 's/rx/Received/g;s/tx/Sent/g;1i Metric,Time,Value' "$CSV_OUTPUT_DIR/WeekPrev.htm"

	cat "$CSV_OUTPUT_DIR/week_summary_this_rx.tmp" "$CSV_OUTPUT_DIR/week_summary_this_tx.tmp" "$CSV_OUTPUT_DIR/week_summary_prev_rx.tmp" "$CSV_OUTPUT_DIR/week_summary_prev_tx.tmp" "$CSV_OUTPUT_DIR/week_summary_prev2_rx.tmp" "$CSV_OUTPUT_DIR/week_summary_prev2_tx.tmp" > "$CSV_OUTPUT_DIR/WeekSummary.htm" 2> /dev/null
	sed -i 's/rx/Received/g;s/tx/Sent/g;1i Metric,Time,Value' "$CSV_OUTPUT_DIR/WeekSummary.htm"

	rm -f "$CSV_OUTPUT_DIR/week"*

	{
		echo ".mode csv"
		echo ".headers on"
		echo ".output $CSV_OUTPUT_DIR/CompleteResults.htm"
		echo "SELECT strftime('%s',[date],'utc') Time,[rx],[tx] FROM fiveminute WHERE strftime('%s',[date],'utc') >= strftime('%s',datetime($timenow,'unixepoch','-30 day')) ORDER BY strftime('%s', [date]) DESC;"
	} > /tmp/dn-vnstat-complete.sql
	"$SQLITE3_PATH" "$VNSTAT_DBASE" < /tmp/dn-vnstat-complete.sql
	rm -f /tmp/dn-vnstat-complete.sql

	dos2unix "$CSV_OUTPUT_DIR/"*.htm

	tmpoutputdir="/tmp/${SCRIPT_NAME}results"
	mkdir -p "$tmpoutputdir"
	mv -f "$CSV_OUTPUT_DIR/CompleteResults"*.htm "$tmpoutputdir/."

	OUTPUTTIMEMODE="$(OutputTimeMode check)"

	if [ "$OUTPUTTIMEMODE" = "unix" ]
	then
		find "$tmpoutputdir/" -name '*.htm' -exec sh -c 'i="$1"; mv -- "$i" "${i%.htm}.csv"' _ {} \;
	elif [ "$OUTPUTTIMEMODE" = "non-unix" ]
	then
		for i in "$tmpoutputdir/"*".htm"; do
			awk -F"," 'NR==1 {OFS=","; print} NR>1 {OFS=","; $1=strftime("%Y-%m-%d %H:%M:%S", $1); print }' "$i" > "$i.out"
		done

		find "$tmpoutputdir/" -name '*.htm.out' -exec sh -c 'i="$1"; mv -- "$i" "${i%.htm.out}.csv"' _ {} \;
		rm -f "$tmpoutputdir/"*.htm
	fi

	if [ ! -f /opt/bin/7za ]
	then
		opkg update
		opkg install p7zip
	fi
	/opt/bin/7za a -y -bsp0 -bso0 -tzip "/tmp/${SCRIPT_NAME}data.zip" "$tmpoutputdir/*"
	mv -f "/tmp/${SCRIPT_NAME}data.zip" "$CSV_OUTPUT_DIR"
	rm -rf "$tmpoutputdir"
	renice 0 $$
}

##----------------------------------------##
## Modified by Martinski W. [2025-Apr-27] ##
##----------------------------------------##
Generate_Images()
{
	Create_Dirs
	Conf_Exists
	ScriptStorageLocation load
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

	if [ $# -eq 0 ] || [ -z "$1" ]
	then Print_Output false "vnstati updating stats for UI" "$PASS" ; fi

	interface="$(_GetInterfaceNameFromConfig_)"
	outputs="s hg d t m"   # what images to generate #

	$VNSTATI_COMMAND -s -i "$interface" -o "$IMAGE_OUTPUT_DIR/vnstat_s.png"
	$VNSTATI_COMMAND -hg -i "$interface" -o "$IMAGE_OUTPUT_DIR/vnstat_hg.png"
	$VNSTATI_COMMAND -d 31 -i "$interface" -o "$IMAGE_OUTPUT_DIR/vnstat_d.png"
	$VNSTATI_COMMAND -m 12 -i "$interface" -o "$IMAGE_OUTPUT_DIR/vnstat_m.png"
	$VNSTATI_COMMAND -t 10 -i "$interface" -o "$IMAGE_OUTPUT_DIR/vnstat_t.png"
	sleep 1

	for output in $outputs
	do
		cp "$IMAGE_OUTPUT_DIR/vnstat_$output.png" "$IMAGE_OUTPUT_DIR/.vnstat_$output.htm"
		rm -f "$IMAGE_OUTPUT_DIR/vnstat_$output.htm"
	done
}

##----------------------------------------##
## Modified by Martinski W. [2025-Apr-27] ##
##----------------------------------------##
Generate_Stats()
{
	if [ ! -f /opt/bin/xargs ]
	then
		Print_Output true "Installing findutils from Entware" "$PASS"
		opkg update
		opkg install findutils
	fi
	if [ -n "$PPID" ]; then
		ps | grep -v grep | grep -v $$ | grep -v "$PPID" | grep -i "$SCRIPT_NAME" | grep generate | awk '{print $1}' | xargs kill -9 >/dev/null 2>&1
	else
		ps | grep -v grep | grep -v $$ | grep -i "$SCRIPT_NAME" | grep generate | awk '{print $1}' | xargs kill -9 >/dev/null 2>&1
	fi
	sleep 3
	Create_Dirs
	Conf_Exists
	ScriptStorageLocation load
	Create_Symlinks
	Auto_Startup create 2>/dev/null
	Auto_Cron create 2>/dev/null
	Auto_ServiceEvent create 2>/dev/null
	Shortcut_Script create
	Process_Upgrade
	interface="$(_GetInterfaceNameFromConfig_)"
	TZ=$(cat /etc/TZ)
	export TZ
	printf "vnstats as of: %s\n\n" "$(date)" > "$VNSTAT_OUTPUT_FILE"
	{
		$VNSTAT_COMMAND -h 25 -i "$interface";
		$VNSTAT_COMMAND -d 8 -i "$interface";
		$VNSTAT_COMMAND -m 6 -i "$interface";
		$VNSTAT_COMMAND -y 5 -i "$interface";
	} >> "$VNSTAT_OUTPUT_FILE"

	if [ $# -eq 0 ] || [ -z "$1" ]
	then
		cat "$VNSTAT_OUTPUT_FILE"
		printf "\n"
		Print_Output false "vnstat_totals summary generated" "$PASS"
	fi
}

##----------------------------------------##
## Modified by Martinski W. [2025-Apr-27] ##
##----------------------------------------##
Generate_Email()
{
	if [ -f /jffs/addons/amtm/mail/email.conf ] && \
	   [ -f /jffs/addons/amtm/mail/emailpw.enc ]
	then
		. /jffs/addons/amtm/mail/email.conf
		PWENCFILE=/jffs/addons/amtm/mail/emailpw.enc
	else
		Print_Output true "$SCRIPT_NAME relies on amtm to send email summaries and email settings have not been configured" "$ERR"
		Print_Output true "Navigate to amtm > em (email settings) to set them up" "$ERR"
		return 1
	fi

	PASSWORD=""
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

	emailtype="$1"
	if [ "$emailtype" = "daily" ]
	then
		Print_Output true "Attempting to send summary statistic email" "$PASS"
		if [ "$(DailyEmail check)" = "text" ]
		then
			# plain text email to send #
			{
				echo "From: \"$FRIENDLY_ROUTER_NAME\" <$FROM_ADDRESS>"
				echo "To: \"$TO_NAME\" <$TO_ADDRESS>"
				echo "Subject: $FRIENDLY_ROUTER_NAME - vnstat-stats as of $(date +"%H.%M on %F")"
				echo "Date: $(date -R)"
				echo ""
				printf "%s\\n\\n" "$(grep " usagestring" "$SCRIPT_STORAGE_DIR/.vnstatusage" | cut -f2 -d'"')"
			} > /tmp/mail.txt
			cat "$VNSTAT_OUTPUT_FILE" >>/tmp/mail.txt
		elif [ "$(DailyEmail check)" = "html" ]
		then
			# html message to send #
			{
				echo "From: \"$FRIENDLY_ROUTER_NAME\" <$FROM_ADDRESS>"
				echo "To: \"$TO_NAME\" <$TO_ADDRESS>"
				echo "Subject: $FRIENDLY_ROUTER_NAME - vnstat-stats as of $(date +"%H.%M on %F")"
				echo "Date: $(date -R)"
				echo "MIME-Version: 1.0"
				echo "Content-Type: multipart/mixed; boundary=\"MULTIPART-MIXED-BOUNDARY\""
				echo "hello there"
				echo ""
				echo "--MULTIPART-MIXED-BOUNDARY"
				echo "Content-Type: multipart/related; boundary=\"MULTIPART-RELATED-BOUNDARY\""
				echo ""
				echo "--MULTIPART-RELATED-BOUNDARY"
				echo "Content-Type: multipart/alternative; boundary=\"MULTIPART-ALTERNATIVE-BOUNDARY\""
			} > /tmp/mail.txt

			echo "<html><body><p>Welcome to your dn-vnstat stats email!</p>" > /tmp/message.html
			echo "<p>$(grep " usagestring" "$SCRIPT_STORAGE_DIR/.vnstatusage" | cut -f2 -d'"')</p>" >> /tmp/message.html

			outputs="s hg d t m"
			for output in $outputs; do
				echo "<p><img src=\"cid:vnstat_$output.png\"></p>" >> /tmp/message.html
			done

			echo "</body></html>" >> /tmp/message.html

			message_base64="$(openssl base64 -A < /tmp/message.html)"
			rm -f /tmp/message.html

			{
				echo ""
				echo "--MULTIPART-ALTERNATIVE-BOUNDARY"
				echo "Content-Type: text/html; charset=utf-8"
				echo "Content-Transfer-Encoding: base64"
				echo ""
				echo "$message_base64"
				echo ""
				echo "--MULTIPART-ALTERNATIVE-BOUNDARY--"
				echo ""
			} >> /tmp/mail.txt

			for output in $outputs
			do
				image_base64="$(openssl base64 -A < "$IMAGE_OUTPUT_DIR/vnstat_$output.png")"
				Encode_Image "vnstat_$output.png" "$image_base64" /tmp/mail.txt
			done

			Encode_Text vnstat.txt "$(cat "$VNSTAT_OUTPUT_FILE")" /tmp/mail.txt

			{
				echo "--MULTIPART-RELATED-BOUNDARY--"
				echo ""
				echo "--MULTIPART-MIXED-BOUNDARY--"
			} >> /tmp/mail.txt
		fi
	elif [ "$emailtype" = "usage" ]
	then
		[ -z "$5" ] && Print_Output true "Attempting to send bandwidth usage email" "$PASS"
		usagepercentage="$2"
		usagestring="$3"
		# plain text email to send #
		{
			echo "From: \"$FRIENDLY_ROUTER_NAME\" <$FROM_ADDRESS>"
			echo "To: \"$TO_NAME\" <$TO_ADDRESS>"
			echo "Subject: $FRIENDLY_ROUTER_NAME - vnstat data usage $usagepercentage warning - $(date +"%H.%M on %F")"
			echo "Date: $(date -R)"
			echo ""
		} > /tmp/mail.txt
		printf "%s" "$usagestring" >> /tmp/mail.txt
	fi

	#Send Email#
	/usr/sbin/curl -s --show-error --url "$PROTOCOL://$SMTP:$PORT" \
	--mail-from "$FROM_ADDRESS" --mail-rcpt "$TO_ADDRESS" \
	--upload-file /tmp/mail.txt \
	--ssl-reqd \
 	--crlf \
	--user "$USERNAME:$PASSWORD" $SSL_FLAG
	if [ $? -eq 0 ]
	then
		echo ""
		[ -z "$5" ] && Print_Output true "Email sent successfully" "$PASS"
		rm -f /tmp/mail.txt
		PASSWORD=""
		return 0
	else
		echo ""
		[ -z "$5" ] && Print_Output true "Email failed to send" "$ERR"
		rm -f /tmp/mail.txt
		PASSWORD=""
		return 1
	fi
}

# encode image for email inline
# $1 : image content id filename (match the cid:filename.png in html document)
# $2 : image content base64 encoded
# $3 : output file
Encode_Image()
{
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
Encode_Text()
{
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

##----------------------------------------##
## Modified by Martinski W. [2025-Apr-28] ##
##----------------------------------------##
DailyEmail()
{
	case "$1" in
		enable)
			if [ $# -lt 2 ] || [ -z "$2" ]
			then
				ScriptHeader
				exitmenu="false"
				printf "\n${BOLD}A choice of emails is available:${CLEARFORMAT}\n"
				printf " 1.  HTML (includes images from WebUI + summary stats as attachment)\n"
				printf " 2.  Plain text (summary stats only)\n\n"
				printf " e.  Exit to main menu\n"

				while true
				do
					printf "\n${BOLD}Choose an option:${CLEARFORMAT}  "
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
							printf "\nPlease choose a valid option\n\n"
						;;
					esac
				done
				printf "\n"

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
			DAILYEMAIL="$(grep "^DAILYEMAIL=" "$SCRIPT_CONF" | cut -f2 -d'=')"
			echo "${DAILYEMAIL:=none}"
		;;
	esac
}

UsageEmail()
{
	case "$1" in
		enable)
			sed -i 's/^USAGEEMAIL.*$/USAGEEMAIL=true/' "$SCRIPT_CONF"
			Check_Bandwidth_Usage
		;;
		disable)
			sed -i 's/^USAGEEMAIL.*$/USAGEEMAIL=false/' "$SCRIPT_CONF"
		;;
		check)
			USAGEEMAIL="$(grep "^USAGEEMAIL=" "$SCRIPT_CONF" | cut -f2 -d"=")"
			if [ "$USAGEEMAIL" = "true" ]; then return 0; else return 1; fi
		;;
	esac
}

##----------------------------------------##
## Modified by Martinski W. [2025-Apr-27] ##
##----------------------------------------##
BandwidthAllowance()
{
	case "$1" in
		update)
			bandwidth="$(echo "$2" | awk '{printf("%.2f", $1);}')"
			sed -i 's/^DATAALLOWANCE.*$/DATAALLOWANCE='"$bandwidth"'/' "$SCRIPT_CONF"
			if [ $# -lt 3 ] || [ -z "$3" ]
			then
				Reset_Allowance_Warnings force
			fi
			Check_Bandwidth_Usage
		;;
		check)
			DATAALLOWANCE="$(grep "^DATAALLOWANCE=" "$SCRIPT_CONF" | cut -f2 -d"=")"
			echo "${DATAALLOWANCE:=1200.00}"
		;;
	esac
}

AllowanceStartDay()
{
	case "$1" in
		update)
			sed -i 's/^MonthRotate .*$/MonthRotate '"$2"'/' "$VNSTAT_CONFIG"
			/opt/etc/init.d/S33vnstat restart >/dev/null 2>&1
			TZ=$(cat /etc/TZ)
			export TZ
			Reset_Allowance_Warnings force
			Check_Bandwidth_Usage
		;;
		check)
			MonthRotate=$(grep "^MonthRotate " "$VNSTAT_CONFIG" | cut -f2 -d" ")
			echo "$MonthRotate"
		;;
	esac
}

AllowanceUnit()
{
	case "$1" in
		update)
		sed -i 's/^ALLOWANCEUNIT.*$/ALLOWANCEUNIT='"$2"'/' "$SCRIPT_CONF"
		;;
		check)
			ALLOWANCEUNIT="$(grep "^ALLOWANCEUNIT=" "$SCRIPT_CONF" | cut -f2 -d"=")"
			echo "${ALLOWANCEUNIT:=G}B"
		;;
	esac
}

##----------------------------------------##
## Modified by Martinski W. [2025-Apr-27] ##
##----------------------------------------##
Reset_Allowance_Warnings()
{
	if { [ $# -gt 0 ] && [ "$1" = "force" ] ; } || \
	   [ "$(date +%d | awk '{printf("%s", $1+1);}')" -eq "$(AllowanceStartDay check)" ]
	then
		rm -f "$SCRIPT_STORAGE_DIR/.warning75"
		rm -f "$SCRIPT_STORAGE_DIR/.warning90"
		rm -f "$SCRIPT_STORAGE_DIR/.warning100"
	fi
}

##----------------------------------------##
## Modified by Martinski W. [2025-Apr-27] ##
##----------------------------------------##
Check_Bandwidth_Usage()
{
	if [ ! -f /opt/bin/jq ]; then
		opkg update
		opkg install jq
	fi
	TZ=$(cat /etc/TZ)
	export TZ

	interface="$(_GetInterfaceNameFromConfig_)"

	rawbandwidthused="$($VNSTAT_COMMAND -i "$interface" --json m | jq -r '.interfaces[].traffic.month[-1] | .rx + .tx')"
	userLimit="$(BandwidthAllowance check)"

	bandwidthused=$(echo "$rawbandwidthused" | awk '{printf("%.2f\n", $1/(1000*1000*1000));}')
	if AllowanceUnit check | grep -q T; then
		bandwidthused=$(echo "$rawbandwidthused" | awk '{printf("%.2f\n", $1/(1000*1000*1000*1000));}')
	fi

	bandwidthpercentage=""
	usagestring=""
	if [ "$(echo "$userLimit 0" | awk '{print ($1 == $2)}')" -eq 1 ]
	then
		bandwidthpercentage="N/A"
		usagestring="You have used ${bandwidthused}$(AllowanceUnit check) of data this cycle; the next cycle starts on day $(AllowanceStartDay check) of the month."
	else
		bandwidthpercentage=$(echo "$bandwidthused $userLimit" | awk '{printf("%.2f\n", $1*100/$2);}')
		usagestring="You have used ${bandwidthpercentage}% (${bandwidthused}$(AllowanceUnit check)) of your ${userLimit}$(AllowanceUnit check) cycle allowance; the next cycle starts on day $(AllowanceStartDay check) of the month."
	fi

	local isVerbose=false
	if [ $# -eq 0 ] || [ -z "$1" ]
	then
		isVerbose=true
		Print_Output false "$usagestring" "$PASS"
	fi

	if [ "$bandwidthpercentage" = "N/A" ] || \
	   [ "$(echo "$bandwidthpercentage 75" | awk '{print ($1 < $2)}')" -eq 1 ]
	then
		echo "var usagethreshold = false;" > "$SCRIPT_STORAGE_DIR/.vnstatusage"
		echo 'var thresholdstring = "";' >> "$SCRIPT_STORAGE_DIR/.vnstatusage"
	elif [ "$(echo "$bandwidthpercentage 75" | awk '{print ($1 >= $2)}')" -eq 1 ] && \
	     [ "$(echo "$bandwidthpercentage 90" | awk '{print ($1 < $2)}')" -eq 1 ]
	then
		"$isVerbose" && Print_Output false "Data use is at or above 75%" "$WARN"
		echo "var usagethreshold = true;" > "$SCRIPT_STORAGE_DIR/.vnstatusage"
		echo 'var thresholdstring = "Data use is at or above 75%";' >> "$SCRIPT_STORAGE_DIR/.vnstatusage"
		if UsageEmail check && [ ! -f "$SCRIPT_STORAGE_DIR/.warning75" ]
		then
			if "$isVerbose"
			then Generate_Email usage "75%" "$usagestring"
			else Generate_Email usage "75%" "$usagestring" silent
			fi
			touch "$SCRIPT_STORAGE_DIR/.warning75"
		fi
	elif [ "$(echo "$bandwidthpercentage 90" | awk '{print ($1 >= $2)}')" -eq 1 ] && \
	     [ "$(echo "$bandwidthpercentage 100" | awk '{print ($1 < $2)}')" -eq 1 ]
	then
		"$isVerbose" && Print_Output false "Data use is at or above 90%" "$ERR"
		echo "var usagethreshold = true;" > "$SCRIPT_STORAGE_DIR/.vnstatusage"
		echo 'var thresholdstring = "Data use is at or above 90%";' >> "$SCRIPT_STORAGE_DIR/.vnstatusage"
		if UsageEmail check && [ ! -f "$SCRIPT_STORAGE_DIR/.warning90" ]
		then
			if "$isVerbose"
			then Generate_Email usage "90%" "$usagestring"
			else Generate_Email usage "90%" "$usagestring" silent
			fi
			touch "$SCRIPT_STORAGE_DIR/.warning90"
		fi
	elif [ "$(echo "$bandwidthpercentage 100" | awk '{print ($1 >= $2)}')" -eq 1 ]
	then
		"$isVerbose" && Print_Output false "Data use is at or above 100%" "$CRIT"
		echo "var usagethreshold = true;" > "$SCRIPT_STORAGE_DIR/.vnstatusage"
		echo 'var thresholdstring = "Data use is at or above 100%";' >> "$SCRIPT_STORAGE_DIR/.vnstatusage"
		if UsageEmail check && [ ! -f "$SCRIPT_STORAGE_DIR/.warning100" ]
		then
			if "$isVerbose"
			then Generate_Email usage "100%" "$usagestring"
			else Generate_Email usage "100%" "$usagestring" silent
			fi
			touch "$SCRIPT_STORAGE_DIR/.warning100"
		fi
	fi
	printf "var usagestring = \"%s\";\\n" "$usagestring" >> "$SCRIPT_STORAGE_DIR/.vnstatusage"
	printf "var daterefeshed = \"%s\";\\n" "$(date +"%Y-%m-%d %T")" >> "$SCRIPT_STORAGE_DIR/.vnstatusage"
}

##----------------------------------------##
## Modified by Martinski W. [2025-Apr-13] ##
##----------------------------------------##
Process_Upgrade()
{
	local restartvnstat=false

	if [ ! -f "$SCRIPT_STORAGE_DIR/.vnstatusage" ]
	then
		echo "var usagethreshold = false;" > "$SCRIPT_STORAGE_DIR/.vnstatusage"
		echo 'var thresholdstring = "";' >> "$SCRIPT_STORAGE_DIR/.vnstatusage"
		echo 'var usagestring = "Not enough data gathered by vnstat";' >> "$SCRIPT_STORAGE_DIR/.vnstatusage"
	fi
	
	if ! grep -q "^UseUTC 0" "$VNSTAT_CONFIG"
	then
		sed -i "/^DatabaseSynchronous/a\\\n# Enable or disable using UTC as timezone in the database for all entries.\n# When enabled, all entries added to the database will use UTC regardless of\n# the configured system timezone. When disabled, the configured system timezone\n# will be used. Changing this setting will not result in already existing data to be modified.\n# 1 = enabled, 0 = disabled.\nUseUTC 0" "$VNSTAT_CONFIG"
		restartvnstat=true
	fi
	
	if [ "$restartvnstat" = "true" ]
	then
		/opt/etc/init.d/S33vnstat restart >/dev/null 2>&1
		Generate_Images silent
		Generate_Stats silent
		Check_Bandwidth_Usage silent
	fi
}

##----------------------------------------##
## Modified by Martinski W. [2025-Apr-13] ##
##----------------------------------------##
ScriptHeader()
{
	clear
	printf "\n"
	printf "${BOLD}##################################################${CLEARFORMAT}\n"
	printf "${BOLD}##                                              ##${CLEARFORMAT}\n"
	printf "${BOLD}##             vnStat on Merlin                 ##${CLEARFORMAT}\n"
	printf "${BOLD}##        for AsusWRT-Merlin routers            ##${CLEARFORMAT}\n"
	printf "${BOLD}##                                              ##${CLEARFORMAT}\n"
	printf "${BOLD}##         %9s on %-18s      ##${CLEARFORMAT}\n" "$SCRIPT_VERSION" "$ROUTER_MODEL"
	printf "${BOLD}##                                              ## ${CLEARFORMAT}\n"
	printf "${BOLD}## https://github.com/de-vnull/vnstat-on-merlin ##${CLEARFORMAT}\n"
	printf "${BOLD}##                                              ##${CLEARFORMAT}\n"
	printf "${BOLD}##################################################${CLEARFORMAT}\n"
	printf "\n"
}

##----------------------------------------##
## Modified by Martinski W. [2025-Apr-28] ##
##----------------------------------------##
MainMenu()
{
	local menuOption  storageLocStr

	MENU_DAILYEMAIL="$(DailyEmail check)"
	if [ "$MENU_DAILYEMAIL" = "html" ]; then
		MENU_DAILYEMAIL="${PASS}ENABLED - HTML"
	elif [ "$MENU_DAILYEMAIL" = "text" ]; then
		MENU_DAILYEMAIL="${PASS}ENABLED - TEXT"
	elif [ "$MENU_DAILYEMAIL" = "none" ]; then
		MENU_DAILYEMAIL="${ERR}DISABLED"
	fi
	MENU_USAGE_ENABLED=""
	if UsageEmail check
	then MENU_USAGE_ENABLED="${PASS}ENABLED"
	else MENU_USAGE_ENABLED="${ERR}DISABLED"
	fi
	MENU_BANDWIDTHALLOWANCE=""
	if [ "$(echo "$(BandwidthAllowance check) 0" | awk '{print ($1 == $2)}')" -eq 1 ]; then
		MENU_BANDWIDTHALLOWANCE="UNLIMITED"
	else
		MENU_BANDWIDTHALLOWANCE="$(BandwidthAllowance check)$(AllowanceUnit check)"
	fi

	storageLocStr="$(ScriptStorageLocation check | tr 'a-z' 'A-Z')"

	printf "WebUI for %s is available at:\n${SETTING}%s${CLEARFORMAT}\n\n" "$SCRIPT_NAME" "$(Get_WebUI_URL)"

	printf "1.    Update stats now\n"
	printf "      Database size: ${SETTING}%s${CLEARFORMAT}\n\n" "$(_GetFileSize_ "$(_GetVNStatDatabaseFilePath_)" HRx)"
	printf "2.    Toggle emails for daily summary stats\n"
	printf "      Currently: ${BOLD}$MENU_DAILYEMAIL${CLEARFORMAT}\n\n"
	printf "3.    Toggle emails for data usage warnings\n"
	printf "      Currently: ${BOLD}$MENU_USAGE_ENABLED${CLEARFORMAT}\n\n"
	printf "4.    Set bandwidth allowance for data usage warnings\n"
	printf "      Currently: ${SETTING}%s${CLEARFORMAT}\n\n" "$MENU_BANDWIDTHALLOWANCE"
	printf "5.    Set unit for bandwidth allowance\n"
	printf "      Currently: ${SETTING}%s${CLEARFORMAT}\n\n" "$(AllowanceUnit check)"
	printf "6.    Set start day of cycle for bandwidth allowance\n"
	printf "      Currently: ${SETTING}%s${CLEARFORMAT}\n\n" "Day $(AllowanceStartDay check) of month"
	printf "b.    Check bandwidth usage now\n"
	printf "      ${SETTING}%s${CLEARFORMAT}\n\n" "$(grep " usagestring" "$SCRIPT_STORAGE_DIR/.vnstatusage" | cut -f2 -d'"')"
	printf "v.    Edit vnstat config\n\n"
	printf "t.    Toggle time output mode\n"
	printf "      Currently ${SETTING}%s${CLEARFORMAT} time values will be used for CSV exports\n\n" "$(OutputTimeMode check)"
	printf "s.    Toggle storage location for stats and config\n"
	printf "      Current location: ${SETTING}%s${CLEARFORMAT}\n\n" "$storageLocStr"
	printf "u.    Check for updates\n"
	printf "uf.   Force update %s with latest version\n\n" "$SCRIPT_NAME"
	printf "e.    Exit %s\n\n" "$SCRIPT_NAME"
	printf "z.    Uninstall %s\n" "$SCRIPT_NAME"
	printf "\n"
	printf "${BOLD}##################################################${CLEARFORMAT}\n"
	printf "\n"

	while true
	do
		printf "Choose an option:  "
		read -r menuOption
		case "$menuOption" in
			1)
				printf "\n"
				if Check_Lock menu
				then
					Generate_Images
					Generate_Stats
					Generate_CSVs
					Clear_Lock
				fi
				PressEnter
				break
			;;
			2)
				printf "\n"
				if [ "$(DailyEmail check)" != "none" ]; then
					DailyEmail disable
				elif [ "$(DailyEmail check)" = "none" ]; then
					DailyEmail enable
				fi
				PressEnter
				break
			;;
			3)
				printf "\n"
				if UsageEmail check; then
					UsageEmail disable
				elif ! UsageEmail check; then
					UsageEmail enable
				fi
				PressEnter
				break
			;;
			4)
				printf "\n"
				if Check_Lock menu; then
					Menu_BandwidthAllowance
				fi
				PressEnter
				break
			;;
			5)
				printf "\n"
				if Check_Lock menu; then
					Menu_AllowanceUnit
				fi
				PressEnter
				break
			;;
			6)
				printf "\n"
				if Check_Lock menu; then
					Menu_AllowanceStartDay
				fi
				PressEnter
				break
			;;
			b)
				printf "\n"
				if Check_Lock menu; then
					Check_Bandwidth_Usage
					Clear_Lock
				fi
				PressEnter
				break
			;;
			v)
				printf "\n"
				if Check_Lock menu; then
					Menu_Edit
				fi
				break
			;;
			t)
				printf "\n"
				if [ "$(OutputTimeMode check)" = "unix" ]; then
					OutputTimeMode non-unix
				elif [ "$(OutputTimeMode check)" = "non-unix" ]; then
					OutputTimeMode unix
				fi
				break
			;;
			s)
				printf "\n"
				if Check_Lock menu
				then
					if [ "$(ScriptStorageLocation check)" = "jffs" ]
					then
					    ScriptStorageLocation usb
					elif [ "$(ScriptStorageLocation check)" = "usb" ]
					then
					    ScriptStorageLocation jffs
					fi
					Create_Symlinks
					Clear_Lock
				fi
				break
			;;
			u)
				printf "\n"
				if Check_Lock menu; then
					Update_Version
					Clear_Lock
				fi
				PressEnter
				break
			;;
			uf)
				printf "\n"
				if Check_Lock menu; then
					Update_Version force
					Clear_Lock
				fi
				PressEnter
				break
			;;
			e)
				ScriptHeader
				printf "\n${BOLD}Thanks for using %s!${CLEARFORMAT}\n\n\n" "$SCRIPT_NAME"
				exit 0
			;;
			z)
				while true
				do
					printf "\n${BOLD}Are you sure you want to uninstall %s? (y/n)${CLEARFORMAT}  " "$SCRIPT_NAME"
					read -r confirm
					case "$confirm" in
						y|Y)
							Menu_Uninstall
							exit 0
						;;
						*) break ;;
					esac
				done
			;;
			*)
				[ -n "$menuOption" ] && \
				printf "\n${REDct}INVALID input [$menuOption]${CLEARFORMAT}"
				printf "\nPlease choose a valid option\n\n"
				PressEnter
				break
			;;
		esac
	done

	ScriptHeader
	MainMenu
}

##----------------------------------------##
## Modified by Martinski W. [2025-Apr-13] ##
##----------------------------------------##
Menu_Install()
{
	ScriptHeader
	Print_Output true "Welcome to $SCRIPT_NAME $SCRIPT_VERSION, a script by dev_null and Jack Yaz" "$PASS"
	sleep 1

	Print_Output false "Checking your router meets the requirements for $SCRIPT_NAME" "$PASS"

	if ! Check_Requirements
	then
		Print_Output false "Requirements for $SCRIPT_NAME not met, please see above for the reason(s)" "$CRIT"
		PressEnter
		Clear_Lock
		rm -f "/jffs/scripts/$SCRIPT_NAME" 2>/dev/null
		exit 1
	fi

	IFACE=""
	printf "\n${BOLD}WAN Interface detected as %s${CLEARFORMAT}\n" "$(Get_WAN_IFace)"
	while true
	do
		printf "\n${BOLD}Is this correct? (y/n)${CLEARFORMAT}  "
		read -r confirm
		case "$confirm" in
			y|Y)
				IFACE="$(Get_WAN_IFace)"
				break
			;;
			n|N)
				while true
				do
					printf "\n${BOLD}Please enter correct interface:${CLEARFORMAT}  "
					read -r iface
					iface_lower="$(echo "$iface" | tr "A-Z" "a-z")"
					if [ "$iface" = "e" ]
					then
						Clear_Lock
						rm -f "/jffs/scripts/$SCRIPT_NAME" 2>/dev/null
						exit 1
					elif [ ! -f "/sys/class/net/$iface_lower/operstate" ] || \
					     [ "$(cat "/sys/class/net/$iface_lower/operstate")" = "down" ]
					then
						printf "\n${ERR}Input is not a valid interface or interface not up, please try again.${CLEARFORMAT}\n"
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
	printf "\n"

	Create_Dirs
	Conf_Exists
	Set_Version_Custom_Settings local "$SCRIPT_VERSION"
	Set_Version_Custom_Settings server "$SCRIPT_VERSION"
	ScriptStorageLocation load
	Create_Symlinks

	Update_File vnstat.conf
	sed -i 's/^Interface .*$/Interface "'"$IFACE"'"/' "$VNSTAT_CONFIG"

	Update_File vnstat-ui.asp
	Update_File S33vnstat
	Update_File shared-jy.tar.gz

	Auto_Startup create 2>/dev/null
	Auto_Cron create 2>/dev/null
	Auto_ServiceEvent create 2>/dev/null
	Shortcut_Script create

	if [ ! -f "$SCRIPT_STORAGE_DIR/.vnstatusage" ]
	then
		echo "var usagethreshold = false;" > "$SCRIPT_STORAGE_DIR/.vnstatusage"
		echo 'var thresholdstring = "";' >> "$SCRIPT_STORAGE_DIR/.vnstatusage"
		echo 'var usagestring = "Not enough data gathered by vnstat";' >> "$SCRIPT_STORAGE_DIR/.vnstatusage"
	fi

	if [ -n "$(pidof vnstatd)" ]
	then
		Print_Output false "Sleeping for 60s before generating initial stats" "$WARN"
		sleep 60
		Generate_Images
		Generate_Stats
		Check_Bandwidth_Usage silent
		Generate_CSVs
	else
		Print_Output false "vnstatd not running, please check system log" "$ERR"
	fi

	Clear_Lock
	ScriptHeader
	MainMenu
}

##----------------------------------------##
## Modified by Martinski W. [2025-Apr-27] ##
##----------------------------------------##
Menu_Startup()
{
	if [ $# -eq 0 ] || [ -z "$1" ]
	then
		Print_Output true "Missing argument for startup, not starting $SCRIPT_NAME" "$ERR"
		exit 1
	elif [ "$1" != "force" ]
	then
		if [ ! -f "${1}/entware/bin/opkg" ]
		then
			Print_Output true "$1 does NOT contain Entware, not starting $SCRIPT_NAME" "$CRIT"
			exit 1
		else
			Print_Output true "$1 contains Entware, starting $SCRIPT_NAME" "$PASS"
		fi
	fi

	NTP_Ready startup
	Check_Lock

	if [ "$1" != "force" ]; then
		sleep 5
	fi
	Create_Dirs
	Conf_Exists
	ScriptStorageLocation load
	Create_Symlinks
	Auto_Startup create 2>/dev/null
	Auto_Cron create 2>/dev/null
	Auto_ServiceEvent create 2>/dev/null
	Set_Version_Custom_Settings local "$SCRIPT_VERSION"
	Shortcut_Script create
	Mount_WebUI
	Clear_Lock
}

##----------------------------------------##
## Modified by Martinski W. [2025-Apr-27] ##
##----------------------------------------##
Menu_BandwidthAllowance()
{
	exitmenu="false"
	bandwidthallowance=""
	ScriptHeader

	while true
	do
		printf "\n${BOLD}Please enter your monthly bandwidth allowance\n"
		printf "(%s, 0 = unlimited, max. 2 decimals):${CLEARFORMAT}  " "$(AllowanceUnit check)"
		read -r allowance

		if [ "$allowance" = "e" ]
		then
			exitmenu="exit"
			printf "\n"
			break
		elif ! Validate_Bandwidth "$allowance"
		then
			printf "\n${ERR}Please enter a valid number (%s, 0 = unlimited, max. 2 decimals)${CLEARFORMAT}\n" "$(AllowanceUnit check)"
		else
			bandwidthallowance="$allowance"
			printf "\n"
			break
		fi
	done

	if [ "$exitmenu" != "exit" ]; then
		BandwidthAllowance update "$bandwidthallowance"
	fi

	Clear_Lock
}

##----------------------------------------##
## Modified by Martinski W. [2025-Apr-27] ##
##----------------------------------------##
Menu_AllowanceUnit()
{
	exitmenu="false"
	allowanceunit=""
	prevallowanceunit="$(AllowanceUnit check)"
	unitsuffix="$(AllowanceUnit check | sed 's/T//;s/G//;')"
	ScriptHeader

	while true
	do
		printf "\n${BOLD}Please select the unit to use for bandwidth allowance:${CLEARFORMAT}\n"
		printf " 1.  G%s\n" "$unitsuffix"
		printf " 2.  T%s\n\n" "$unitsuffix"
		printf " Choose an option:  "
		read -r unitchoice
		case "$unitchoice" in
			1)
				allowanceunit="G"
				printf "\n"
				break
			;;
			2)
				allowanceunit="T"
				printf "\n"
				break
			;;
			e)
				exitmenu="exit"
				printf "\n"
				break
			;;
			*)
				printf "\nPlease choose a valid option\n\n"
			;;
		esac
	done

	if [ "$exitmenu" != "exit" ]
	then
		AllowanceUnit update "$allowanceunit"

		allowanceunit="$(AllowanceUnit check)"
		if [ "$prevallowanceunit" != "$allowanceunit" ]
		then
			scalefactor=1000

			scaletype="none"
			if [ "$prevallowanceunit" != "$(AllowanceUnit check)" ]
			then
				if echo "$prevallowanceunit" | grep -q G && AllowanceUnit check | grep -q T; then
					scaletype="divide"
				elif echo "$prevallowanceunit" | grep -q T && AllowanceUnit check | grep -q G; then
					scaletype="multiply"
				fi
			fi

			if [ "$scaletype" != "none" ]
			then
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

Menu_AllowanceStartDay()
{
	exitmenu="false"
	allowancestartday=""
	ScriptHeader

	while true
	do
		printf "\n${BOLD}Please enter day of month that your bandwidth allowance\nresets (1-28):${CLEARFORMAT}  "
		read -r startday

		if [ "$startday" = "e" ]
		then
			exitmenu="exit"
			printf "\n"
			break
		elif ! Validate_Number "$startday"
		then
			printf "\n${ERR}Please enter a valid number (1-28)${CLEARFORMAT}\n"
		else
			if [ "$startday" -lt 1 ] || [ "$startday" -gt 28 ]
			then
				printf "\n${ERR}Please enter a number between 1 and 28${CLEARFORMAT}\n"
			else
				allowancestartday="$startday"
				printf "\n"
				break
			fi
		fi
	done

	if [ "$exitmenu" != "exit" ]; then
		AllowanceStartDay update "$allowancestartday"
	fi

	Clear_Lock
}

##----------------------------------------##
## Modified by Martinski W. [2025-Apr-28] ##
##----------------------------------------##
Menu_Edit()
{
	texteditor=""
	exitmenu="false"

	printf "\n${BOLD}A choice of text editors is available:${CLEARFORMAT}\n"
	printf " 1.  nano (recommended for beginners)\n"
	printf " 2.  vi\n\n"
	printf " e.  Exit to main menu\n"

	while true
	do
		printf "\n${BOLD}Choose an option:${CLEARFORMAT}  "
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
				printf "\nPlease choose a valid option\n\n"
			;;
		esac
	done

	if [ "$exitmenu" != "true" ]
	then
		oldmd5="$(md5sum "$VNSTAT_CONFIG" | awk '{print $1}')"
		$texteditor "$VNSTAT_CONFIG"
		newmd5="$(md5sum "$VNSTAT_CONFIG" | awk '{print $1}')"
		if [ "$oldmd5" != "$newmd5" ]
		then
			/opt/etc/init.d/S33vnstat restart >/dev/null 2>&1
			TZ=$(cat /etc/TZ)
			export TZ
			Check_Bandwidth_Usage silent
			Clear_Lock
			printf "\n"
			PressEnter
		fi
	fi
	Clear_Lock
}

##-------------------------------------##
## Added by Martinski W. [2025-Apr-27] ##
##-------------------------------------##
_RemoveMenuAddOnsSection_()
{
   if [ $# -lt 2 ] || [ -z "$1" ] || [ -z "$2" ] || \
      ! echo "$1" | grep -qE "^[1-9][0-9]*$" || \
      ! echo "$2" | grep -qE "^[1-9][0-9]*$" || \
      [ "$1" -ge "$2" ]
   then return 1 ; fi
   local BEGINnum="$1"  ENDINnum="$2"

   if [ -n "$(sed -E "${BEGINnum},${ENDINnum}!d;/${webPageLineTabExp}/!d" "$TEMP_MENU_TREE")" ]
   then return 1
   fi
   sed -i "${BEGINnum},${ENDINnum}d" "$TEMP_MENU_TREE"
   return 0
}

##-------------------------------------##
## Added by Martinski W. [2025-Apr-27] ##
##-------------------------------------##
_FindandRemoveMenuAddOnsSection_()
{
   local BEGINnum  ENDINnum  retCode=1

   if grep -qE "^${BEGIN_MenuAddOnsTag}$" "$TEMP_MENU_TREE" && \
      grep -qE "^${ENDIN_MenuAddOnsTag}$" "$TEMP_MENU_TREE"
   then
       BEGINnum="$(grep -nE "^${BEGIN_MenuAddOnsTag}$" "$TEMP_MENU_TREE" | awk -F ':' '{print $1}')"
       ENDINnum="$(grep -nE "^${ENDIN_MenuAddOnsTag}$" "$TEMP_MENU_TREE" | awk -F ':' '{print $1}')"
       _RemoveMenuAddOnsSection_ "$BEGINnum" "$ENDINnum" && retCode=0
   fi

   if grep -qE "^${webPageMenuAddons}$" "$TEMP_MENU_TREE" && \
      grep -qE "${webPageHelpSupprt}$" "$TEMP_MENU_TREE"
   then
       BEGINnum="$(grep -nE "^${webPageMenuAddons}$" "$TEMP_MENU_TREE" | awk -F ':' '{print $1}')"
       ENDINnum="$(grep -nE "${webPageHelpSupprt}$" "$TEMP_MENU_TREE" | awk -F ':' '{print $1}')"
       if [ -n "$BEGINnum" ] && [ -n "$ENDINnum" ] && [ "$BEGINnum" -lt "$ENDINnum" ]
       then
           BEGINnum="$((BEGINnum - 2))" ; ENDINnum="$((ENDINnum + 3))"
           if [ "$(sed -n "${BEGINnum}p" "$TEMP_MENU_TREE")" = "," ] && \
              [ "$(sed -n "${ENDINnum}p" "$TEMP_MENU_TREE")" = "}" ]
           then
               _RemoveMenuAddOnsSection_ "$BEGINnum" "$ENDINnum" && retCode=0
           fi
       fi
   fi
   return "$retCode"
}

##----------------------------------------##
## Modified by Martinski W. [2025-Apr-27] ##
##----------------------------------------##
Menu_Uninstall()
{
	if [ -n "$PPID" ]; then
		ps | grep -v grep | grep -v $$ | grep -v "$PPID" | grep -i "$SCRIPT_NAME" | grep generate | awk '{print $1}' | xargs kill -9 >/dev/null 2>&1
	else
		ps | grep -v grep | grep -v $$ | grep -i "$SCRIPT_NAME" | grep generate | awk '{print $1}' | xargs kill -9 >/dev/null 2>&1
	fi
	Print_Output true "Removing $SCRIPT_NAME..." "$PASS"
	Auto_Startup delete 2>/dev/null
	Auto_Cron delete 2>/dev/null
	Auto_ServiceEvent delete 2>/dev/null

	LOCKFILE=/tmp/addonwebui.lock
	FD=386
	eval exec "$FD>$LOCKFILE"
	flock -x "$FD"

	MyWebPage=""
	[ -s "$SCRIPT_DIR/vnstat-ui.asp" ] && Get_WebUI_Page "$SCRIPT_DIR/vnstat-ui.asp"
	if [ -n "$MyWebPage" ] && \
	   [ "$MyWebPage" != "NONE" ] && \
	   [ -f "$TEMP_MENU_TREE" ]
	then
		sed -i "\\~$MyWebPage~d" "$TEMP_MENU_TREE"
		rm -f "$SCRIPT_WEBPAGE_DIR/$MyWebPage"
		rm -f "$SCRIPT_WEBPAGE_DIR/$(echo "$MyWebPage" | cut -f1 -d'.').title"
		_FindandRemoveMenuAddOnsSection_
		umount /www/require/modules/menuTree.js 2>/dev/null
		mount -o bind "$TEMP_MENU_TREE" /www/require/modules/menuTree.js
	fi

	flock -u "$FD"
	rm -f "$SCRIPT_DIR/vnstat-ui.asp"
	rm -rf "$SCRIPT_WEB_DIR" 2>/dev/null

	Shortcut_Script delete
	/opt/etc/init.d/S33vnstat stop >/dev/null 2>&1
	touch /opt/etc/vnstat.conf
	opkg remove --autoremove vnstati2
	opkg remove --autoremove vnstat2

	rm -f /opt/etc/init.d/S33vnstat
	rm -f /opt/etc/vnstat.conf

	Reset_Allowance_Warnings force
	rm -f "$SCRIPT_STORAGE_DIR/.vnstatusage"
	rm -f "$SCRIPT_STORAGE_DIR/.v2upgraded"
	rm -rf "$IMAGE_OUTPUT_DIR"
	rm -rf "$CSV_OUTPUT_DIR"

	SETTINGSFILE="/jffs/addons/custom_settings.txt"
	sed -i '/dnvnstat_version_local/d' "$SETTINGSFILE"
	sed -i '/dnvnstat_version_server/d' "$SETTINGSFILE"

	printf "\n${BOLD}Would you like to keep the vnstat\ndata files and configuration? (y/n)${CLEARFORMAT}  "
	read -r confirm
	case "$confirm" in
		y|Y)
			:
		;;
		*)
			rm -rf "$SCRIPT_STORAGE_DIR"
			rm -rf /opt/var/lib/vnstat
			rm -f /opt/etc/vnstat.conf
		;;
	esac

	rm -f "/jffs/scripts/$SCRIPT_NAME"
	Clear_Lock
	Print_Output true "Uninstall completed" "$PASS"
}

##----------------------------------------##
## Modified by Martinski W. [2025-Apr-13] ##
##----------------------------------------##
NTP_Ready()
{
	if [ "$(nvram get ntp_ready)" -eq 1 ]
	then
		if [ $# -gt 0 ] && [ "$1" = "startup" ]
		then
			Print_Output true "NTP is synced." "$PASS"
			/opt/etc/init.d/S33vnstat start >/dev/null 2>&1
		fi
		return 0
	fi

	local theSleepDelay=15  ntpMaxWaitSecs=600  ntpWaitSecs

	if [ "$(nvram get ntp_ready)" -eq 0 ]
	then
		Check_Lock
		ntpWaitSecs=0
		Print_Output true "Waiting for NTP to sync..." "$WARN"

		while [ "$(nvram get ntp_ready)" -eq 0 ] && [ "$ntpWaitSecs" -lt "$ntpMaxWaitSecs" ]
		do
			if [ "$ntpWaitSecs" -gt 0 ] && [ "$((ntpWaitSecs % 30))" -eq 0 ]
			then
			    Print_Output true "Waiting for NTP to sync [$ntpWaitSecs secs]..." "$WARN"
			fi
			sleep "$theSleepDelay"
			ntpWaitSecs="$((ntpWaitSecs + theSleepDelay))"
		done
		if [ "$ntpWaitSecs" -ge "$ntpMaxWaitSecs" ]
		then
			Print_Output true "NTP failed to sync after 10 minutes. Please resolve!" "$CRIT"
			Clear_Lock
			exit 1
		else
			Print_Output true "NTP has synced [$ntpWaitSecs secs], $SCRIPT_NAME will now continue." "$PASS"
			/opt/etc/init.d/S33vnstat start >/dev/null 2>&1
			Clear_Lock
		fi
	fi
}

### function based on @Adamm00's Skynet USB wait function ###
Entware_Ready()
{
	if [ ! -f /opt/bin/opkg ]
	then
		Check_Lock
		sleepcount=1
		while [ ! -f /opt/bin/opkg ] && [ "$sleepcount" -le 10 ]
		do
			Print_Output true "Entware not found, sleeping for 10s (attempt $sleepcount of 10)" "$ERR"
			sleepcount="$((sleepcount + 1))"
			sleep 10
		done
		if [ ! -f /opt/bin/opkg ]
		then
			Print_Output true "Entware not found and is required for $SCRIPT_NAME to run, please resolve" "$CRIT"
			Clear_Lock
			exit 1
		else
			Print_Output true "Entware found, $SCRIPT_NAME will now continue" "$PASS"
			Clear_Lock
		fi
	fi
}

Show_About()
{
	cat <<EOF
About
  $SCRIPT_NAME implements an NTP time server for AsusWRT Merlin
  with charts for daily, weekly and monthly summaries of performance.
  A choice between ntpd and chrony is available.
License
  $SCRIPT_NAME is free to use under the GNU General Public License
  version 3 (GPL-3.0) https://opensource.org/licenses/GPL-3.0
Help & Support
  https://www.snbforums.com/forums/asuswrt-merlin-addons.60/?prefix_id=22
Source code
  https://github.com/jackyaz/$SCRIPT_NAME
EOF
	printf "\n"
}

### function based on @dave14305's FlexQoS show_help function ###
Show_Help()
{
	cat <<EOF
Available commands:
  $SCRIPT_NAME about              explains functionality
  $SCRIPT_NAME update             checks for updates
  $SCRIPT_NAME forceupdate        updates to latest version (force update)
  $SCRIPT_NAME startup force      runs startup actions such as mount WebUI tab
  $SCRIPT_NAME install            installs script
  $SCRIPT_NAME uninstall          uninstalls script
  $SCRIPT_NAME generate           get latest data from vnstat. also runs outputcsv
  $SCRIPT_NAME summary            get daily summary data from vnstat. runs automatically at end of day. also runs outputcsv
  $SCRIPT_NAME outputcsv          create CSVs from database, used by WebUI and export
  $SCRIPT_NAME develop            switch to development branch
  $SCRIPT_NAME stable             switch to stable branch
EOF
	printf "\n"
}

##-------------------------------------##
## Added by Martinski W. [2025-Apr-27] ##
##-------------------------------------##
TMPDIR="$SHARE_TEMP_DIR"
SQLITE_TMPDIR="$TMPDIR"
export SQLITE_TMPDIR TMPDIR

if [ -f "/opt/share/$SCRIPT_NAME.d/config" ]
then SCRIPT_STORAGE_DIR="/opt/share/$SCRIPT_NAME.d"
else SCRIPT_STORAGE_DIR="/jffs/addons/$SCRIPT_NAME.d"
fi

SCRIPT_CONF="$SCRIPT_STORAGE_DIR/config"
CSV_OUTPUT_DIR="$SCRIPT_STORAGE_DIR/csv"
IMAGE_OUTPUT_DIR="$SCRIPT_STORAGE_DIR/images"
VNSTAT_CONFIG="$SCRIPT_STORAGE_DIR/vnstat.conf"
VNSTAT_COMMAND="vnstat --config $VNSTAT_CONFIG"
VNSTATI_COMMAND="vnstati --config $VNSTAT_CONFIG"
VNSTAT_OUTPUT_FILE="$SCRIPT_STORAGE_DIR/vnstat.txt"

##----------------------------------------##
## Modified by Martinski W. [2025-Apr-27] ##
##----------------------------------------##
if [ $# -eq 0 ] || [ -z "$1" ]
then
	NTP_Ready
	Entware_Ready
	Create_Dirs
	Conf_Exists
	ScriptStorageLocation load
	Create_Symlinks
	Auto_Startup create 2>/dev/null
	Auto_Cron create 2>/dev/null
	Auto_ServiceEvent create 2>/dev/null
	Shortcut_Script create
	_CheckFor_WebGUI_Page_
	Process_Upgrade
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
		Check_Lock
		Generate_Images silent
		Generate_Stats silent
		Check_Bandwidth_Usage silent
		Generate_CSVs
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
	outputcsv)
		NTP_Ready
		Entware_Ready
		Generate_CSVs
	;;
	service_event)
		if [ "$2" = "start" ] && [ "$3" = "$SCRIPT_NAME" ]
		then
			rm -f /tmp/detect_vnstat.js
			Check_Lock webui
			sleep 3
			echo 'var vnstatstatus = "InProgress";' > /tmp/detect_vnstat.js
			Generate_Images silent
			Generate_Stats silent
			Check_Bandwidth_Usage silent
			Generate_CSVs
			echo 'var vnstatstatus = "Done";' > /tmp/detect_vnstat.js
			Clear_Lock
			exit 0
		elif [ "$2" = "start" ] && [ "$3" = "${SCRIPT_NAME}config" ]
		then
			Conf_FromSettings
			exit 0
		elif [ "$2" = "start" ] && [ "$3" = "${SCRIPT_NAME}checkupdate" ]
		then
			Update_Check
			exit 0
		elif [ "$2" = "start" ] && [ "$3" = "${SCRIPT_NAME}doupdate" ]
		then
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
		Create_Dirs
		Conf_Exists
		ScriptStorageLocation load
		Create_Symlinks
		Auto_Startup create 2>/dev/null
		Auto_Cron create 2>/dev/null
		Auto_ServiceEvent create 2>/dev/null
		Shortcut_Script create
		Process_Upgrade
		Generate_Images silent
		Generate_Stats silent
		Check_Bandwidth_Usage silent
		Generate_CSVs
		Clear_Lock
		exit 0
	;;
	uninstall)
		Menu_Uninstall
		exit 0
	;;
	about)
		ScriptHeader
		Show_About
		exit 0
	;;
	help)
		ScriptHeader
		Show_Help
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
		ScriptHeader
		Print_Output false "Parameter [$*] is NOT recognised." "$ERR"
		Print_Output false "For a list of available commands run: $SCRIPT_NAME help" "$SETTING"
		exit 1
	;;
esac
