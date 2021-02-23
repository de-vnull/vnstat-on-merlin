# Install cmd
```sh
/usr/sbin/curl --retry 3 "https://raw.githubusercontent.com/de-vnull/vnstat-on-merlin/jackyaz-dev/dn-vnstat.sh" -o "/jffs/scripts/dn-vnstat" && chmod 0755 /jffs/scripts/dn-vnstat && /jffs/scripts/dn-vnstat install
```

# What is this repository for?
This is an implementation of vnstat/vnstati for use on AsusWRT-Merlin routers. This effort was started to enable accurate measurement of data use locally, to replace the internal monitoring tool, `Traffic Analyzer > Traffic Monitor`, which suffers from (false) “17GB” usage bursts on some routers on some firmware (e.g., RT-AC68U on 386.1). This became a particular concern when Xfinity began implementing 1.2GB caps nationwide in January 2021 (note: postponed in the Northeast until 3Q2021).

# Acknowlegements
-   This was created with support from @Jack Yaz, who provided support to create the “AddOn” vnstat-ui scaffold and scripting. Many thanks, Jack!
-   My thanks also to @thelonelycoder of snbforums, for the use of his emailing process, which is part of his Diversion ad-blocking application for Merlin.
-   And this wouldn't be possible without the vnstat program, so my thanks to Teemu Toivola too.

# Original intent
-   This was created for personal use, but is being published for the potential benefit to the community of users. Improvement and enhancement suggestions are welcomed (as is collaboration to automate portions or the entire process).
    -   The vnstat application and accompanying UI have been tested on Merlin 384.19, 386.1 beta 1-5 and 386.1 release, on RT-AC66U_B1 (on AC68U firmware) and RT-AX86U 86.1 beta 1-5 and 386.1 release. The totals are consistent with the firmware "Traffic Monitor/Traffic Analyzer". The totals reported by vnstat are slightly higher than those currently being reported by Comcast (about 10-15%).
    -   Feedback and comments are welcomed. PM to @dev_null @ snbforums
    -   Any errors or omissions will be corrected upon notice, but the user assumes all risk.

# Version
-   Version: 0.0.1

# How do I get set up?
-   Note: there is a "TL;DR checklist" at the bottom for an ordered list of actions; being familiar with the design, rationale and constraints is encouraged.

## Minimum requirements
-   AsusWRT Merlin version 384.19 or later. Tested on 386.1 beta 1-5 and 386.1 release version.
    -   This has not been tested on Johns LTS firmware, so compatibility is unknown (please report success or failure!).
-   Diversion and it's corresponding install of Entware. Diversion does not need to be running, as long as Entware is installed.
-   Properly setup email (`Diversion` "communications" option) to use the encrypted username/password to email vnstat reports.
    -   Please run an Entware update to ensure the most current repository lists are available.
    -   You may be able to install Entware separately from Diversion but I have not tested this method.

## Configuration
-   The Enware application vnstat can be run without any UI, 100% from the CLI via ssh.
    -   In this use case, requirements are simply to install (via entware) the vnstat executable.
    -   Note: if running solely from the CLI, there is no need to install vnstati, which exports vnstats to image form, or imagemagick, which is used to create an image of the daily report - both are components of the UI (see below).
-   The following packages must be installed:
    -   vnstat and vnstati: install using command `opkg install vnstat` and `opkg install vnstati`
        -   Note: in some cases vnstati may install with vnstat, so the separate vnstati install may not be required.
    -   Optional: imagemagick – install using command `opkg install imagemagick`. This program is used to create an image of the daily (or weekly) email message with the recent totals. If this functionality is not desired, this application is not required.
    -   Required: `opkg install libjpeg-turbo` to render the images on the UI.

## Dependencies
-   Applications described above. Scripts as described below.

## Deployment instructions for the non-UI (CLI via SSH) version
-   No additional steps are required. Usage should be recorded automatically circa every 30 seconds to the db file.
-   To view current status, issue the `vnstat` command from the CLI. There are several additional CLI options (view days, top ten, hourly, monthly, etc) - see image below.
    -   This type of deployment still supports daily or other frequency of email
-   The CLI vnstat report and options view
![CLI](https://github.com/de-vnull/vnstat-on-merlin/blob/main/images/vnstat-cli-red.PNG)

## Deployment instructions for the UI
-   The UI is a work in progress - this was created principally for my own use and there is no guarantee it will work on other devices (or that you will like the look). Each section can be hidden (a @JackYaz feature) if you prefer not to see that view. Hidden sections should be 'sticky' and retain that setting.
-   The AddOns tab showing the vnstat/vnstati view and daily email report collapsed
![Collapsed](https://github.com/de-vnull/vnstat-on-merlin/blob/main/images/Screenshot_2021-02-Vnstat-xp.png)

Purpose of each component is described below - be sure to note where modifications are needed:
-   **div-email.sh** - script which sends vnstat reports by email to one or more users. Uses the email configuration from Diversion. See notes below.

**OR**
-   **send-vnstat**: optional script that takes the output from vnstat-stats.sh and emails it to one or more users. It is launched by cron job (I run it at 23:59 local each evening).
    -   If you use `send-vnstat`, you need to update the email address (from, password, and to), your router name, and the path to your "Traffic" directory (this script aggregates the message components and then backs them up to the Traffic folder for future reference.).
    -   This script is a kludge and stores email credentials in plain text - see alternative option below.
        -   **This script should be used only when Diversion's email communication is not enabled or available.**
        -   Use at your own risk (obviously).

**Email update**: thanks to @elorimer's script, and with the agreement of @theloneycoder, there is now a better option for the vnstat-stats email process.
This adds another dependency - leveraging @thelonelycoder's Diversion "communication" email process - but solves other issues, including support for platforms other than gmail, secure storage of passwords, etc.

Here are the steps to follow to use Diversion's email process:
1.  Make sure that Diversion's email communication is set up (amtm > 1 (Diversion) > c (communication) > 5 (edit email settings, test email)) with the account of your choice.
2.  In /jffs/scripts, create the div-email.sh from the scripts folder. Make sure it's executable (octal 0755).
3.  Test by running
```sh
/opt/bin/vnstat -u && sh /jffs/scripts/vnstat-stats && sh /jffs/scripts/div-email.sh Vnstat-stats /home/root/vnstat.txt
```
4.  If not using send-vnstat, you can delete it (to secure your email details).
-   A sample of the email message output - sent as an attachment
![Email_sample](https://github.com/de-vnull/vnstat-on-merlin/blob/main/images/vnstat-email-xp.png)

## How to run tests
-   Test for core vnstat functionality: after a period of usage, issue `vnstat` from the CLI. You should see a report of data usage. If not, reinstall vnstat or check that the correct interface is being monitored.
-   UI functionality: reboot or re-run `dn-vnstat startup force`. Check that the cron job calling the vnstati update is working. You should see the usage as images in the vnstat UI tab under AddOns (see picture below).

# Miscellaneous notes
-   The vnstats UI page may require a hard refresh (CTRL+F5 or equivalent) to see the latest stats. The page does not cache, but depending on the browser this auto cache clear may or may not be honored, or may require some time to elapse.
-   On 386.1 I have noticed that cronjobs are occassionally deleted. If you find that happening, my workaround is to add custom cron entries to the "nat-start" script. This will write/re-write the cronjob entries. Be sure that you update both locations if you make any changes.
-   Note: db files can in some instances be moved across devices, but only of the same architecture (e.g., ARM7 to ARM7). Different architecture will result in an error and call for a db reinitialization. I have not found a workaround to cross-architecture errors.
-   There is also the ability to export the data for review within other programs (`vnstat --dumpdb`). I have not used this functionality.
-   Make sure your scripts are executable (chmod).
-   It has been reported that with **hardware acceleration** implemented, the data counts provided by vnstat are no more accurate than the built-in tools (which is to say, not accurate).

# TL;DR - checklist: just the steps sans context and commentary
1.  Min requirements: Merlin 384.19 or later, Entware, for UI view: 1 or more Jack Yaz scripts
2.  SSH into router and install vnstat and vnstati: `opkg install vnstat` and `opkg install vnstati`.
    -   Install imagemagick if full UI functionality is desired: `opkg install imagemagick`.
    -   Install image rendering libraries: `opkg install libjpeg-turbo`
3.  See testing procedures above (vnstat core functionality)
4.  In the `send-vnstat` (if used) script, modify attributes for email of usage stats (sample is for gmail)
5.  See testing procedures for the UI functionality above

# Legal and licensing
-   This process is unlicensed, but certain components, while all are publically available, may have different licensing requirements. To the best of my knowledge, the methods outlined above do not violate any existing licensing terms.
-   If you port, improve, extend or otherwise modify the concepts included in this process, I only ask for a courtesy attribution, a reference back to this work.
-   Please publish any modifications or improvements back for the general community to benefit.

# Who do I contact with comments or questions?
-   Repo owner or admin - dev_null @ snbforums
-   Other community or team contact - dev_null @ snbforums
