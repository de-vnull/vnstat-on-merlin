# vnstat-on-merlin - _BETA 2_ - non-UI version

# README #

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

	- Copy __div-email.sh__ script from this location (https://github.com/de-vnull/vnstat-on-merlin/tree/main/scripts) to /jffs/scripts. This script sends vnstat reports by email to one or more users. Uses the email configuration from Diversion.
	- Copy __vnstat-stats.sh__ script from this location (https://github.com/de-vnull/vnstat-on-merlin/tree/main/scripts) to /jffs/scripts. This script concatenates the daily, weekly and monthly usage into a text file which is part of the daily email.

If you're running the `div-email.sh` script with the non-UI version of vnstat, add this line to the `services-start` and the `service-event` scripts in the `/jffs/scripts` directory:

```
cru a vnstat_daily "59 23 * * * /opt/bin/vnstat -u && sh /jffs/scripts/vnstat-stats.sh && sh /jffs/scripts/div-email.sh Vnstat-stats /home/root/vnstat.txt"
```

* If you want to run vnstat without the UI, __are not running Diversion__, and still wish to email daily usage:
	- Copy __vnstat-stats.sh__ script from this location (https://github.com/de-vnull/vnstat-on-merlin/tree/main/scripts) to /jffs/scripts. This script concatenates the daily, weekly and monthly usage into a text file which is part of the daily email.
	- Copy __send-vnstat.sh__ script from this location (https://github.com/de-vnull/vnstat-on-merlin/tree/main/scripts) to /jffs/scripts. 
		- The `send-vnstat` script requires you to update the email address (from, password, and to), your router name and other information.
		- This script stores email credentials in plain text. Use only when you have control over access to the router.
			- __This script should be used only when Diversion's email communication is not enabled or available.__

If you're running the `send-vnstat.sh` script, add this line to the `services-start` and the `service-event` scripts in the `/jffs/scripts` directory:

```
cru a vnstat_daily "59 23 * * * /opt/bin/vnstat -u && sh /jffs/scripts/vnstat-stats.sh && sh /jffs/scripts/send-vnstat.sh"
```

* The CLI vnstat report and options view


![CLI](https://github.com/de-vnull/vnstat-on-merlin/blob/main/images/vnstat-cli-red.PNG)




### Legal and licensing ###
	
* This process is unlicensed, but certain components, while all are publically available, may have different licensing requirements. To the best of my knowledge, the methods contained in the script and described above do not violate any existing licensing terms.
* If you port, improve, extend or otherwise modify the concepts included in this process, I only ask for a courtesy attribution, a reference back to this work.
* Please publish any modifications or improvements back for the general community to benefit.


### Who do I contact with comments or questions? ###

* Repo owner or admin - dev_null @ snbforums
* Other community or team contact - dev_null @ snbforums
