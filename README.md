# Install cmd - need to update and put in body
```sh
/usr/sbin/curl --retry 3 "https://raw.githubusercontent.com/de-vnull/vnstat-on-merlin/jackyaz-dev/dn-vnstat.sh" -o "/jffs/scripts/dn-vnstat" && chmod 0755 /jffs/scripts/dn-vnstat && /jffs/scripts/dn-vnstat install
```

# vnstat-on-merlin

__BETA 2__

# README #

### What is this repository for? ###

* This is an implementation of vnstat/vnstati for use on AsusWRT-Merlin routers. This effort was started to enable accurate measurement of data use in a local database, to supplement the internal monitoring tool, `Traffic Analyzer > Traffic Monitor`, which will episodically record false “17GB” usage bursts. This only occurs on some routers on some firmware (e.g., RT-AC68U and RT-AC66U_B1 on 386.1). 

* This became a particular concern when Xfinity began implementing 1.2GB caps nationwide in January 2021 (note: postponed in the Northeast until 2022).

### Acknowlegements ###

- This project was created with an incredible amount of support from @JackYaz, who provided support to create the “AddOn” vnstat-ui scaffold and scripting.

    - Words cannot adequetly describe my gratefulness - Jack literally spent hours, scripting, consolidating, testing, providing feedback, and patiently responding to my every question. The install, menu and functioning integrated removal of old installs and email is 100% @JackYaz.

   - My thanks to @thelonelycoder, for allowing this script to leverage Diversion's email process.
 
   - My thanks to @Martineau for the initial scripts that got the ball rolling.
 
    - And this wouldn't be possible without the vnstat and vnstati applications, so my thanks to Teemu Toivola too.

### Original intent ###
* This was created for personal use, but is being published for the potential benefit to the community of users. Improvement and enhancement suggestions are welcomed (I already have a few in mind).
	
	- The vnstat application and accompanying UI have been tested on Merlin 384.19, 386.1 beta 1-5 and 386.1 release, on RT-AC66U_B1 (on AC68U firmware) and RT-AX86U 86.1 beta 1-5 and 386.1 release. 
	- Preliminary testing on John's fork on MIPs demostrates functionality, though the "CLI" image on the UI is not created (it appears to be an issue with Imagemagick). A potential fix is included in future enhancements).
	- The totals are consistent with the firmware "Traffic Monitor/Traffic Analyzer". The totals reported by vnstat are slightly higher than those currently being reported by Comcast (about 10-15%).

	- Feedback and comments are welcomed. PM to @dev_null @ snbforums
	- Any errors or omissions will be corrected upon notice, but the user assumes all risk.

### Version ###
* Version: 0.9.3a
* This is "beta 2"

### How do I get set up? ###

* Prior versions (alpha, beta 1, and manual) required a series of steps to be taken for full install. This __beta 2__ implementation is nearly completely automated, with several additional options available through the `dn-vnstat` command menu, post install.

* Minimum requirements:
	- AsusWRT Merlin version 384.19 or later. Tested on 386.1 beta 1-5 and 386.1 release version.
		- Initial testing on John's fork appears to demonstrate expected functionality, except that the "CLI report" image isn't working. Report any further experiences (include router model and firmware version).
	- Diversion and it's corresponding install of Entware. Diversion does not need to be running, as long as Entware is installed.
    - Properly setup email (`Diversion` "communications" option) to use the encrypted username/password to email vnstat reports.
		- Please run an Entware update to ensure the most current repository lists are available.
		- Please test Diversion email (`amtm > 1 - Diversion > c - Communication > 5 - Edit email settings, send testmail > follow steps to set up and test`) before enabling the Vnstat on Merlin usage email.
			
* Configuration
	- The Enware application `vnstat` can be run without any UI, 100% from the CLI via ssh.
		- In this use case, requirements are simply to install (via Entware) the vnstat executable.
		- __Note: if running vnstat solely from the CLI (SSH), there is no need to install via the script below. Install using the command `opkg install vnstat`.__

* Dependencies for the UI version
	- Hardware and firmware described above.

* Database configuration
	- Unlike in the alpha/beta1/manual installations, there is no separate database configuration required. This is now part of the automation.
	- _If you have a custom location for your database files, you will need to either update `vnstat.conf` with those locations, re-initialize the database in the standard location, or terminate vnstatd (`killall vnstatd`) and copy your database files to the standard location._

* Deployment instructions for the non-UI (CLI via SSH) version
	- No additional steps are required. Usage should be recorded automatically circa every 30 seconds to the db file.
	- To view current status, issue the `vnstat` command from the CLI. There are several additional CLI options (view days, top ten, hourly, monthly, etc) - see image below.
	- This type of deployment can support daily summary email (but require additional downloads and manual steps).


### Install script - beta 2 ###

* From the CLI, issue the following command (triple click to select all):
```
/usr/sbin/curl --retry 3 "https://raw.githubusercontent.com/de-vnull/vnstat-on-merlin/jackyaz-dev/dn-vnstat.sh" -o "/jffs/scripts/dn-vnstat" && chmod 0755 /jffs/scripts/dn-vnstat && /jffs/scripts/dn-vnstat install
```
	
* The AddOns tab showing the vnstat/vnstati view and daily email report collapsed

![Collapsed](https://github.com/de-vnull/vnstat-on-merlin/blob/main/images/Screenshot_2021-02-Vnstat-xp.png)			

* A sample of the email message output - sent as plain text.

![Email_sample](https://github.com/de-vnull/vnstat-on-merlin/blob/main/images/vnstat-email-xp.png)


### How do I upgrade from a manual install or alpha or beta1? ###
* This beta2 version is re-written from the ground up, and therefore any scripts from previous installations need to be removed.
* The vnstat application and, most critically, the interface database files, are to be left intact.
* A script has been created which removes the previous installed scripts. However, a reboot is required in order to remove anything still in use (e.g., the old UI page)
* To clean out the old files, run this command from the CLI
```
curl --retry 3 "https://raw.githubusercontent.com/de-vnull/vnstat-on-merlin/development/scripts/vom-rio.sh" -o "/jffs/scripts/vom-rio.sh" && chmod 755 "/jffs/scripts/vom-rio.sh" && /jffs/scripts/vom-rio.sh
```
* Follow the prompts, typing YES when prompted
* Reboot when finished
* Run the beta2 install script above.


### Miscellaneous notes ###
* The vnstats UI page may require a hard refresh (CTRL+F5 or equivalent) to see the latest stats. The page does not cache, but depending on the browser this auto cache clear may or may not be honored, or may require some time to elapse.
* Note: db files can in some instances be moved across devices, but only of the same architecture (e.g., ARM7 to ARM7). Different architecture will result in an error and call for a db reinitialization. I have not found a workaround to cross-architecture errors.
* There is also the ability to export the data for review within other programs (`vnstat --dumpdb`). I have not used this functionality.
* It has been reported that with _hardware acceleration_ implemented, the data counts provided by vnstat are no more accurate than the built-in tools (which is to say, not accurate).



### Miscellaneous configuration ###

* If you want to run vnstat without the UI, __are running Diversion__, and still wish to have a daily email, follow these steps:

	- Copy __div-email.sh__ script from this location to /jffs/scripts. This script sends vnstat reports by email to one or more users. Uses the email configuration from Diversion.
	- Copy __vnstat-stats.sh__ script from this location to /jffs/scripts. This script concatenates the daily, weekly and monthly usage into a text file which is part of the daily email.

If you're running the `div-email.sh` script with the non-UI version of vnstat, add this line to the `services-start` and the `service-event` scripts in the `/jffs/scripts` directory:

```
cru a vnstat_daily "59 23 * * * /opt/bin/vnstat -u && sh /jffs/scripts/vnstat-stats && sh /jffs/scripts/div-email.sh Vnstat-stats /home/root/vnstat.txt"
```

* If you want to run vnstat without the UI, __are not running Diversion__, and still wish to email daily usage:
	- Copy __vnstat-stats.sh__ script from this location. This script concatenates the daily, weekly and monthly usage into a text file which is part of the daily email.
	- Copy __send-vnstat__ script from this location. 
		- The `send-vnstat` script requires you to update the email address (from, password, and to), your router name and other information.
		- This script stores email credentials in plain text. Use only when you have control over access to the router.
			- __This script should be used only when Diversion's email communication is not enabled or available.__

If you're running the `send-vnstat` script, add this line to the `services-start` and the `service-event` scripts in the `/jffs/scripts` directory:

```
cru a vnstat_daily "59 23 * * * /opt/bin/vnstat -u && sh /jffs/scripts/vnstat-stats.sh && sh /jffs/scripts/send-vnstat"
```

### Other views ###
* The CLI vnstat report and options view


![CLI](https://github.com/de-vnull/vnstat-on-merlin/blob/main/images/vnstat-cli-red.PNG)




### Legal and licensing ###
	
* This process is unlicensed, but certain components, while all are publically available, may have different licensing requirements. To the best of my knowledge, the methods outlined above do not violate any existing licensing terms.
* If you port, improve, extend or otherwise modify the concepts included in this process, I only ask for a courtesy attribution, a reference back to this work.
* Please publish any modifications or improvements back for the general community to benefit.


### Who do I contact with comments or questions? ###

* Repo owner or admin - dev_null @ snbforums
* Other community or team contact - dev_null @ snbforums
