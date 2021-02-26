# Install cmd
```sh
/usr/sbin/curl --retry 3 "https://raw.githubusercontent.com/de-vnull/vnstat-on-merlin/jackyaz-dev/dn-vnstat.sh" -o "/jffs/scripts/dn-vnstat" && chmod 0755 /jffs/scripts/dn-vnstat && /jffs/scripts/dn-vnstat install
```

# vnstat-on-merlin

__*vnstat-on-merlin beta 2 - JY version*__

# README #

### What is this repository for? ###

* This is an implementation of vnstat/vnstati for use on AsusWRT-Merlin routers. This effort was started to enable accurate measurement of data use locally, to replace the internal monitoring tool, `Traffic Analyzer > Traffic Monitor`, which suffers from (false) “17GB” usage bursts on some routers on some firmware (e.g., RT-AC68U on 386.1). This became a particular concern when Xfinity began implementing 1.2GB caps nationwide in January 2021 (note: postponed in the Northeast until 2022).

### Acknowlegements ###

- This project was created with an incredible amount of support from @JackYaz, who provided support to create the “AddOn” vnstat-ui scaffold and scripting.


    - Words cannot adequetly describe my gratefulness - he literally spent hours, scripting, consolidating, testing and patiently responding to my every question.

    - My thanks to @Martineau for the initial scripts that got the ball rolling.
  
    - My thanks to @thelonelycoder, for the use of his emailing process, which is part of his Diversion ad-blocking application for Merlin.
 
    - And this wouldn't be possible without the vnstat and vnstati applications, so my thanks to Teemu Toivola too.

### Original intent ###
* This was created for personal use, but is being published for the potential benefit to the community of users. Improvement and enhancement suggestions are welcomed (as is collaboration to automate portions or the entire process).
	
	- The vnstat application and accompanying UI have been tested on Merlin 384.19, 386.1 beta 1-5 and 386.1 release, on RT-AC66U_B1 (on AC68U firmware) and RT-AX86U 86.1 beta 1-5 and 386.1 release. The totals are consistent with the firmware "Traffic Monitor/Traffic Analyzer". The totals reported by vnstat are slightly higher than those currently being reported by Comcast (about 10-15%).

	- Feedback and comments are welcomed. PM to @dev_null @ snbforums
	- Any errors or omissions will be corrected upon notice, but the user assumes all risk.

### Version ###
* Version: 0.9.9
* Install script version: 0.9.9 (see below)

### How do I get set up? ###

* Prior versions (alpha, beta1 and manual) required a series of steps to be taken. This beta2 implementation is largely automated, with several additional options available through the `dn-vnstat.sh` menu, post install.

* Minimum requirements:
	- AsusWRT Merlin version 384.19 or later. Tested on 386.1 beta 1-5 and 386.1 release version.
		- This has not been tested on Johns LTS firmware, so compatibility is unknown (please report success or failure!).
	- Diversion and it's corresponding install of Entware. Diversion does not need to be running, as long as Entware is installed.
    - Properly setup email (`Diversion` "communications" option) to use the encrypted username/password to email vnstat reports.
		- Please run an Entware update to ensure the most current repository lists are available.
		- You may be able to install Entware separately from Diversion but I have not tested this method.
			
* Configuration
	- The Enware application vnstat can be run without any UI, 100% from the CLI via ssh.
		- In this use case, requirements are simply to install (via entware) the vnstat executable.
		- __Note: if running vnstat solely from the CLI (SSH), there is no need to install via the script below. Just install using command `opkg install vnstat`.__

* Dependencies
	- Firmware and applications described above. Scripts as described below.

* Database configuration
	- Unlike in the alpha/beta1/manual installations, there is no separate configuration required. This is now part of the automation.

* Deployment instructions for the non-UI (CLI via SSH) version
	- No additional steps are required. Usage should be recorded automatically circa every 30 seconds to the db file.
	- To view current status, issue the `vnstat` command from the CLI. There are several additional CLI options (view days, top ten, hourly, monthly, etc) - see image below.
	- This type of deployment still supports daily or other frequency of email (set up via dn-vnstat.sh menu)


### Install script - beta2 ###

* From the CLI, issue the following command (triple click to select all):
```
/usr/sbin/curl --retry 3 "https://raw.githubusercontent.com/de-vnull/vnstat-on-merlin/jackyaz-dev/dn-vnstat.sh" -o "/jffs/scripts/dn-vnstat" && chmod 0755 /jffs/scripts/dn-vnstat && /jffs/scripts/dn-vnstat install
```
	
* The AddOns tab showing the vnstat/vnstati view and daily email report collapsed

![Collapsed](https://github.com/de-vnull/vnstat-on-merlin/blob/main/images/Screenshot_2021-02-Vnstat-xp.png)
		
* Purpose of each component is described below - be sure to note where modifications are needed:
	- __dn-vnstat.sh__: main dn-vnstat script. Creates the UI and cron jobs, and contains a menu for various settings.
	- __div-email.sh__ - script which sends vnstat reports by email to one or more users. Uses the email configuration from Diversion. See notes below.
	OR
	- __send-vnstat__: optional script that takes the output from vnstat-stats.sh and emails it to one or more users. Must be added manually along with the associated cron job.
		- If you use `send-vnstat`, you need to update the email address (from, password, and to), your router name, and the path to your "Traffic" directory (this script aggregates the message components and then backs them up to the Traffic folder for future reference.).
		- This script is a kludge and stores email credentials in plain text - see alternative option below.
			- __This script should be used only when Diversion's email communication is not enabled or available.__
			- Use at your own risk (obviously).
			

* A sample of the email message output - sent as an attachment

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

If you're running the `send-vnstat` script, add this line to the `services-start` and the `service-event` scripts in the `/jffs/scripts` directory:

```
cru a vnstat_daily "59 23 * * * /opt/bin/vnstat -u && sh /jffs/scripts/vnstat-stats && sh /jffs/scripts/send-vnstat" # this forces a data use update refreshes the vnstat daily use report and emails it
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
