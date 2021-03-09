# vnstat-on-merlin - _BETA 2_

# README #

### What is this repository for? ###

* This is an implementation of vnstat/vnstati for use on AsusWRT-Merlin routers. This effort was started to enable accurate measurement of data use in a local database, to supplement the internal monitoring tool, `Traffic Analyzer > Traffic Monitor`, which will peridically record false “17GB” usage bursts. This only occurs on some routers on some firmware (e.g., RT-AC68U and RT-AC66U_B1 on 386.1). 

* This became a particular concern when Xfinity began implementing 1.2TB caps nationwide in January 2021 (note: postponed in the Northeast until 2022).

### Acknowledgements ###

- This project was created with an incredible amount of support from @JackYaz, who provided support to create the “AddOn” vnstat-ui scaffold and scripting.

    - Words cannot adequetly describe my gratefulness - Jack literally spent hours scripting, consolidating, testing, providing feedback, and patiently responding to feedback and answering my every question, no matter how mundane (or inane). The install, menu and functioning integrated removal of old installs and email is 100% credit to @JackYaz.

   - My thanks to @thelonelycoder, for allowing this script to leverage Diversion's email process.
 
   - My thanks to @Martineau for the initial scripts that got the ball rolling.
 
    - And this wouldn't be possible without the vnstat and vnstati applications, so my thanks to Teemu Toivola too.

### Original intent ###
* This was created for personal use, but is being published for the potential benefit to the community of users. Improvement and enhancement suggestions are welcomed (I already have a few in mind).
	
	- The vnstat application and accompanying UI have been tested on Merlin 384.19, 386.1 beta 1-5 and 386.1 and 1_2 release, on RT-AC66U_B1 (on AC68U firmware) and RT-AX86U 386.1 beta 1-5 and 386.1 release. 
	- Preliminary testing on John's fork on MIPs demostrates functionality, though the "CLI" image on the UI is not created (it appears to be an issue with Imagemagick). A potential fix is included in future enhancements.
	- The totals are consistent with the firmware "Traffic Monitor/Traffic Analyzer". The totals reported by vnstat are slightly higher than those currently being reported by Comcast (about 10-15%).

	- Feedback and comments are welcomed. PM to @dev_null @ snbforums
	- Any errors or omissions will be corrected upon notice, but the user assumes all risk.

### Version ###
* Version: 0.9.4
* This is "beta 2"

### How do I get set up? ###

* Prior versions (alpha, beta 1, and manual) required a series of steps to be taken for full install. This __beta 2__ implementation is nearly completely automated, with several additional options available through the `dn-vnstat` command menu, post install. __A manual reboot may be required to purge duplicate vnstat-UI pages.__

* Minimum requirements:
	- AsusWRT Merlin version 384.19 or later. Tested on 386.1 beta 1-5 and 386.1 release versions. 
		- Earlier versions (384 only) may likewise function; kindly report any further experiences (include router model and firmware version).
		- Initial testing on John's fork appears to demonstrate expected functionality, except that the "CLI report" image isn't working. Kindly report any further experiences (include router model and firmware version).
	- Hardware tested RT-AC66U_B1, RT-AC68U, RT-AC86U, RT-AX86U and RT-N66U.
	- Diversion and it's corresponding install of Entware. Diversion does not need to be running, as long as Entware is installed.
    - Properly setup email (`Diversion` "communications" option) to use the encrypted username/password to email vnstat reports.
		- Please run an Entware update to ensure the most current repository lists are available.
		- Please test Diversion email (`amtm > 1 - Diversion > c - Communication > 5 - Edit email settings, send testmail` > follow steps to set up and test) before enabling the Vnstat on Merlin usage email.

* Dependencies for the UI version
	- Hardware and firmware described above.

* Database configuration
	- Unlike in the alpha/beta1/manual installations, there is no separate database configuration required for the UI-installed version. This is now part of the automation.
	- _Note: if you have a custom location for your database files, you will need to either update `vnstat.conf` with those locations, re-initialize the database in the standard location (losing history), or export and re-import as described below._

	* Export/import: if you'd like to take a "belt and suspenders" (or "belt and braces" for those on the Continent), you can
	1. Export with `vnstat --exportdb > /path/to/vnstat-export-db.txt` which will export your current database
	2. Re-import the data by running
		a. `/opt/etc/init.d/S33vnstat kill`, followed by 
		b. `vnstat --importdb /path/to/vnstat-export-db.txt -i eth0 --force` (enter the correct interface for your setup), followed by 
		c. `/opt/etc/init.d/S33vnstat start`

### Install script - UI version - beta 2 ###

* From the CLI, issue the following command (triple click to select all):
```
/usr/sbin/curl --retry 3 "https://raw.githubusercontent.com/de-vnull/vnstat-on-merlin/main/dn-vnstat.sh" -o "/jffs/scripts/dn-vnstat" && chmod 0755 /jffs/scripts/dn-vnstat && /jffs/scripts/dn-vnstat install
```
	
* The AddOns tab showing the UI

![UI-full](https://github.com/de-vnull/vnstat-on-merlin/blob/main/images/Screenshot_2021-02-28_dn-vnstat-gr-xp.png)		

* The dn-vnstat menu

![Menu](https://github.com/de-vnull/vnstat-on-merlin/blob/main/images/dn-vnstat-menu.png)

* A sample of the email message output - sent as plain text.

![Email_sample](https://github.com/de-vnull/vnstat-on-merlin/blob/main/images/vnstat-email-xp.png)


### Upgrade from a manual install or alpha or beta 1 ###
* This __beta2__ version is re-written from the ground up, and therefore any previous installations (manual or automated) need to be removed.
* The updated install script will detect any previously installed scripts and will inform you that these will be removed. __Database files will be left intact on the device.__
* If you don't want to migrate to the new version, you can abort the install.


### Miscellaneous notes ###
* The vnstats UI page may require a hard refresh (`CTRL+F5` or equivalent) to see the latest stats. The page does not cache, but depending on the browser this auto cache clear may or may not be honored, or may require some time to elapse.
* Note: db files can in some instances be moved across devices, but only of the same architecture (e.g., ARM7 to ARM7). Different architecture will result in an error and requires a db reinitialization. 
* There is also the ability to export the data for review within other programs (`vnstat --dumpdb`). 
* It has been reported that with _hardware acceleration_ implemented, the data counts provided by vnstat are no more accurate than the built-in tools (which is to say, not accurate).



### Non-UI configuration steps ###

* Install instructions for the __non-UI__ (CLI via SSH) version
	- No additional steps are required. Usage should be recorded automatically circa every 30 seconds to the db file.
	- To view current status, issue the `vnstat` command from the CLI. There are several additional CLI options (view days, top ten, hourly, monthly, etc) - see image below.
	- This type of deployment can support daily summary email (but require additional downloads and manual steps).

* Configuration
	- The Enware application `vnstat` can be run without any UI, 100% from the CLI via ssh.
		- In this use case, requirements are simply to install (via Entware) the vnstat executable.
		- __Note: if running vnstat solely from the CLI (SSH), there is no need to install via the UI install script.__ 
		- Install from the CLI using the command `opkg install vnstat`.

* If you want to run vnstat without the UI, __are running Diversion__, and still wish to have a daily email, follow these steps:

	- Copy __div-email.sh__ script from this location (https://github.com/de-vnull/vnstat-on-merlin/tree/VoM_CLI/scripts) to /jffs/scripts. This script sends vnstat reports by email to one or more users. Uses the email configuration from Diversion.
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

### Returning the default theme and rate columns ###

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
	
* This process is unlicensed, but certain components, while all are publically available, may have different licensing requirements. To the best of my knowledge, the methods contained in the script and described above do not violate any existing licensing terms.
* If you port, improve, extend or otherwise modify the concepts included in this process, I only ask for a courtesy attribution, a reference back to this work.
* Please publish any modifications or improvements back for the general community to benefit.


### Who do I contact with comments or questions? ###

* Repo owner or admin - dev_null @ snbforums
* Other community or team contact - dev_null @ snbforums

# Donations

* If you like this software and wish to make a donation, the author requests that you make a contribution to __your favorite local charity__, or to one of his:

    http://www.careandshareofel.org/monetary-donations.html
    
    https://www.uri.edu/giving/
    
    https://www.uwsect.org/give
    
* Let's pay it forward and thanks for your consideration!


