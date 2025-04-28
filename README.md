# vnstat-on-merlin - _Release - R1 and R2_

## v2.0.7  [Updated on 2025-Apr-27]

# README #

### See changelog for details ###
* This documentation includes the first release (R1) based on vnStat 1.18 and the second release (R2) based on vnStat 2.6.
* MIPS-based routers will stay on R1 since vnStat 2.x is not available for the platform.

### What is this repository for? ###

* This is an implementation of vnStat for use on AsusWRT-Merlin routers. This effort was started to enable accurate measurement of data use in a local database (for privacy reasons), and as an alternative the internal monitoring tool, Traffic Analyzer > Traffic Monitor, which will periodically record false “17GB” usage bursts. This "false spike", as some have called it, only occurs on some routers on some firmware (I personally experienced it with RT-AC68U firmware on RT-AC66U_B1).
	- Accurate tracking of data usage became a particular concern when Comcast/Xfinity stated their intention to implement 1.2TB caps nationwide.
        - The totals are consistent with the firmware "Traffic Monitor/Traffic Analyzer".
       	- The totals reported by vnStat are slightly higher than those currently being reported by Comcast (about 10-12%), but you should validate your use-case.

### Acknowledgements ###

- I'd like to acknowledge @Jack Yaz who is responsible for the programming behind the concept - Jack is a true partner in every sense of the word!

   - My thanks to @thelonelycoder, for allowing this script to leverage Diversion's email process.
 
   - My thanks to @Martineau for the initial scripts that got the ball rolling.
 
    - And this wouldn't be possible without the vnstat and vnstati applications, so my thanks to Teemu Toivola (and who has provided feedback to Jack and me during development of R1 and beyond).

### Notes about data use, units and monitoring ###

* vnStat-on-Merlin R1 (in the 'Legacy' branch) uses the Entware version of vnStat, currently version 1.18. This is an older version of the application. This version has certain limitations, described here: https://github.com/de-vnull/vnstat-on-merlin/blob/main/more-info.md .
* vnStat-on-Merlin R2 uses the Entware version of vnStat2, currently version 2.7. This is a recent release of the software. It is supported by ARM and AARCH architectures only.
* vnStat-on-Merlin data-use and data-limit reporting __should be considered a guide__, an approximation of actual use. __vnStat-reported totals may or may not match that reported by your provider__, your cycle may start and stop on a different day of the month, a partial month (especially the first month) or the data use reported could be affected by variables such as hardware acceleration, settings that bypass the TCP/IP stack or as mundane as scheduled reboots. __You must conduct proper due diligence to determine if the usage reported by vnStat aligns with your provider.__


### Versions ###
* Version: 1.0.2 - also known as R1 - all architectures are supported
* Version: 2.0.0 - also known as R2 - ARM and AARCH architectures are supported

### How do I get set up? ###

* R1 installation and update from Beta 3
	- A full, scripted install is available through `amtm`, the Asuswrt-Merlin Terminal Menu, version 3.1.9 or later.
        - You may need to update amtm (`amtm` > `uu`)
        - A CLI command is available on the vnStat-on-Merlin github portal below, but should not be required.
    	- If you are coming from beta 3, run a `u` (update) or `uf` (forced update).
        - See below if coming from an earlier version.
    		- During an update, custom settings in `vnstat.conf` are retained. However you are encouraged to compare the default version (copied into the install folder) against your current configuration.

* R2 installation and update from R1 - choose one of the following procedures:
	- Running `amtm` and installing from the menu will identify the architecture of the router and install the proper version
	- Choosing `u` update from within the vnStat-on-Merlin menu will identify the architecture of the router and install the proper version
	- Clicking the `Update` button from within the vnStat-on-Merlin UI will identify the architecture of the router and install the proper version
		- Upgrading from R1 to R2 will __erase any custom vnstat configurations__. You may need to redo any custom settings (e.g., date formats).

### Minimum requirements ###

* AsusWRT Merlin version 384.19 or later for __R1__.
	- R1 has been tested on 384.19 through 386.2_6 release version.
	- Earlier versions (384-series only) may likewise function; kindly report any further experiences (include router model and firmware version).
	- Initial testing on John's fork appears to demonstrate expected functionality. Kindly report any further experiences (include router model and firmware version).
* AsusWRT Merlin version 386.1 or later for __R2__. 
	- R2 has been tested on 386.2_6 release version.
	- No version of John's fork have been tested (no supported hardware available) - please report success/failure.
	- Hardware tested during development includes RT-AC66U_B1, RT-AC68U, RT-AC86U, RT-AX86U and RT-N66U.
* Dependencies:
	- Diversion and Entware.
	- Properly setup email via Diversion "communications" option is required. vnStat-on-Merlin uses the encrypted username/password from Diversion to email reports.
	- Please run an Entware update to ensure the most current repository lists are available.
		- Please test Diversion email (`amtm > 1 - Diversion > c - Communication > 5 - Edit email settings, send testmail` > follow steps to set up and test) before enabling the vnStat on Merlin usage email.
		- Once email is set up, Diversion does not need to be running if you don't use it (`amtm > 1 - Diversion > d - Diversion > 1 - disable`), but should remain installed.

* Database configuration - _pre-R1 ("Legacy") installs only_
	- Unlike in the alpha/beta1/manual installations, there is no separate database configuration required. Existing database files will not be deleted.
		- If you have a custom location for your database files (legacy of the manual and alpha builds), you will need to either update vnstat.conf with those locations, or re-initialize the database in the standard location (losing history), or copy your database files to the standard location. See below for detailed steps on backing up and restoring your database files.

	- _Note: if you have a custom location for your database files, you will need to either update `vnstat.conf` with those locations, re-initialize the database in the standard location (losing history), or export and re-import as described below._

	* Export/import: if you'd like to take a "belt and suspenders" (or "belt and braces" for those on the Continent), you can
	1. Export with `vnstat --exportdb > /path/to/vnstat-export-db.txt` which will export your current database
	2. Re-import the data by running
		a. `/opt/etc/init.d/S33vnstat kill`, followed by 
		b. `vnstat --importdb /path/to/vnstat-export-db.txt -i eth0 --force` (enter the correct interface for your setup), followed by 
		c. `/opt/etc/init.d/S33vnstat start`

### Install script - full (UI-enabled) version ###

* Install of Vnstat on Merlin is available in the `amtm` menu (from amtm version 3.1.9 and later). That is currently the best way to install and manage.
* Alternative install: from the CLI, issue the following command (triple click to select all):
```
/usr/sbin/curl --retry 3 "https://raw.githubusercontent.com/de-vnull/vnstat-on-merlin/main/dn-vnstat.sh" -o "/jffs/scripts/dn-vnstat" && chmod 0755 /jffs/scripts/dn-vnstat && /jffs/scripts/dn-vnstat install
```
	
* The AddOns tab showing the UI

![UI-full](https://github.com/de-vnull/vnstat-on-merlin/blob/main/images/Screenshot_2021-02-28_dn-vnstat-gr-xp.png)		

* The dn-vnstat menu

![Menu](https://github.com/de-vnull/vnstat-on-merlin/blob/main/images/CLI-vR1.PNG)

* A sample of the email message output - sent as html or plain text.

![Email_html](https://github.com/de-vnull/vnstat-on-merlin/blob/main/images/HTML-daily.PNG)

![Email_text](https://github.com/de-vnull/vnstat-on-merlin/blob/main/images/Txt-daily.PNG)


### Upgrade from a manual install or alpha or beta 1 - R1 (Legacy) branch only ###

* The R1 beta 3 version and later was re-written from the ground up, and therefore any previous installations (manual or automated) need to be removed.
* The R1 installer for later versions (beta 3 and later) automatically performs this uninstall. __Database files will be left intact on the device.__
* If you don't want to migrate to the R1 version from the manual install (pre-R1), you can abort the install (but extensive testing has demonstrated this update to be be straightforward).


### Miscellaneous notes ###

* The vnstats UI page may require a hard refresh (`CTRL+F5` or equivalent) to see the latest stats. The page does not cache, but depending on the browser this auto cache clear may or may not be honored, or may require some time to elapse. This refresh issue has been mostly addressed in R1 and later.
* Export and import of data usage tracking is possible for __Version R1 only__, even across architectures (tested ARM <-> MIPS and ARM <-> AARCH). See instructions below. __Export and import functions have been removed in vnStat 2.x and are therefore not available in R2.__
* There is also the ability to export the data for review within other programs (`vnstat --dumpdb`) - __R1 only__. 
* It has been reported that with _hardware acceleration_ implemented, the data counts provided by vnstat are no more accurate than the built-in tools (which is to say, not accurate).
* For the __day of month reset__ attribute in the menu (0.9.5 and later) and vnstat.conf: the count does not reset until the following month; described here: https://github.com/de-vnull/vnstat-on-merlin/blob/main/more-info.md#MonthRotate .



### Non-UI configuration steps - vnStat command line only ###

* Note: the below has been tested with vnStat 1.18; these _may_ work with vnStat 2.x (vnstat2 in the Entware repository) but _has not been tested_.

* Install instructions for the __non-UI__ (CLI via SSH) version of vnStat - for vnStat Entware-hosted version 1.18 only
	- No additional steps are required. Usage should be recorded automatically circa every 300 seconds to the db file.
	- To view current status, issue the `vnstat` command from the CLI. There are several additional CLI options (view days, top ten, hourly, monthly, etc) - see image below.
	- This type of deployment can support daily summary email (but require additional downloads and manual steps).
	- This type of deployment is __not supported__ but is published in the community interest.

* Configuration
	- The Enware application `vnstat` can be run without any UI, 100% from the CLI via ssh.
		- In this use case, requirements are simply to install (via Entware) the vnstat executable.
		- __Note: if running vnstat solely from the CLI (SSH), there is no need to install via the UI install script.__ 
		- Install from the CLI using the command `opkg install vnstat` for version 1.18 (or `opkg install vnstat2` for version 2.x).

* If you want to run vnstat without the UI, __are running Diversion__, and still wish to have a daily email, follow these steps:

	- Copy __div-email.sh__ script from this location (https://github.com/de-vnull/vnstat-on-merlin/tree/VoM_CLI/scripts) to /jffs/scripts. This script sends vnstat reports by email to one or more users. Uses the email configuration from Diversion.
	- __ **Note: for `amtm` v 3.2.1 or later, use `div-email-amtm-3-2-1.sh`**__ - rename to `div-email.sh` once copied - this contains the new path to the encrypted password file and path to openssl (required post-3.2.1).
	- Copy __vnstat-stats.sh__ script from this location (https://github.com/de-vnull/vnstat-on-merlin/tree/VoM_CLI/scripts) to /jffs/scripts. This script concatenates the daily, weekly and monthly usage into a text file which is part of the daily email.
	- Note: you man need to add the _Equifax_Secure_Certificate_Authority.pem_ file to /jffs/scripts if you get an error message (gmail particularly).

If you're running the `div-email.sh` script with the non-UI version of vnstat, add this line to the `services-start` and the `service-event` scripts in the `/jffs/scripts` directory:

```
cru a vnstat_daily "59 23 * * * /opt/bin/vnstat -u && sh /jffs/scripts/vnstat-stats.sh && sh /jffs/scripts/div-email.sh Vnstat-stats /home/root/vnstat.txt"
```

* If you want to run vnstat without the UI, __are not running Diversion__, and still wish to email daily usage:
	- Copy __vnstat-stats.sh__ script from this location (https://github.com/de-vnull/vnstat-on-merlin/tree/VoM_CLI/scripts) to /jffs/scripts. This script concatenates the daily, weekly and monthly usage into a text file which is part of the daily email.
	- Copy __send-vnstat.sh__ script from this location (https://github.com/de-vnull/vnstat-on-merlin/tree/VoM_CLI/scripts) to /jffs/scripts. 
		- The `send-vnstat` script requires you to update the email address (from, password, and to), your router name and other information.
		- This script stores email credentials in plain text. Use only when you have control over access to the router.
			- __This script should be used only when Diversion's email communication is not enabled or available.__
	- Note: you man need to add the _Equifax_Secure_Certificate_Authority.pem_ file to /jffs/scripts if you get an error message (gmail particularly).

If you're running the `send-vnstat.sh` script, add this line to the `services-start` and the `service-event` scripts in the `/jffs/scripts` directory:

```
cru a vnstat_daily "59 23 * * * /opt/bin/vnstat -u && sh /jffs/scripts/vnstat-stats.sh && sh /jffs/scripts/send-vnstat.sh"
```

* The CLI vnstat report and options view


![CLI](https://github.com/de-vnull/vnstat-on-merlin/blob/main/images/vnstat-cli-red.PNG)

### Returning the default theme and rate columns - R1 only ###

To restore the default vnstat colors and rate columns, edit `vnstat.conf` (via the `dn-vnstat` script), make the following changes. 

To restore the colors, make these changes:
```
# image colors
CBackground     "FFFFFF"
CEdge           "AEAEAE"
CHeader         "606060"
CHeaderTitle    "FFFFFF"
CHeaderDate     "FFFFFF"
CText           "000000"
CLine           "B0B0B0"
CLineL          "-"
CRx             "92CF00"
CTx             "606060"
CRxD            "-"
CTxD            "-"
```

To add the 'rate' columns back:
```
# output style
# 0 = minimal & narrow, 1 = bar column visible
# 2 = same as 1 except rate in summary and weekly
# 3 = rate column visible
OutputStyle 1

# show hours with rate (1 = enabled, 0 = disabled)
HourlyRate 1

# show rate in summary (1 = enabled, 0 = disabled)
SummaryRate 1
```
See here for default view: https://imgur.com/a/ufMQgeA

### Legal and licensing ###
	
* This process is licensed under GPL 3, but certain components, while all are publically available, may have different licensing requirements. To the best of my knowledge, the methods contained in the script and described above do not violate any existing licensing terms.
* If you port, improve, extend or otherwise modify the concepts included in this process, I only ask for a courtesy attribution, a reference back to this work.
* Please publish any modifications or improvements back for the general community to benefit.


### Who do I contact with comments or questions? ###

* Repo owner or admin - dev_null @ snbforums
* Other community or team contact - dev_null or Jack Yaz @ snbforums


#
# Donations

* If you like this software and wish to make a donation, the author requests that you make a contribution to __your favorite local charity__, or to one of his:

    http://www.careandshareofel.org/monetary-donations.html
    
    https://www.uri.edu/giving/
    
    https://www.uwsect.org/give
    
* Some employers will __match your charitable donation__ amount, multiplying your contribution. Ask your manager or HR representative.
* Let's pay it forward and thanks for your consideration!


