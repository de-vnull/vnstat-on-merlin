# Changelog #

Note: R1 runs on all supported architectures (ARM, AARCH, MIPS). R2 runs only on ARM and AARCH. This is due to the availability of vnStat 2.x in the Entware repository.

# Version R2 (based on vnStat 2.x) #

### v 2.0.7 - 27-Apr-2025 ###
  * Fixes to make sure the vnstat Entware service is started during the reboot sequence after NTP is synced.
  * Modified code so that every time the SSH CLI menu is run, it checks if the WebGUI page has already been mounted. If not found mounted, the script will run the code to remount the WebGUI.
  * Improved code that creates (during installation) and removes (during uninstallation) the "AddOns" menu tab entry for the WebGUI to make sure it checks for and takes into account other add-ons that may have been installed before or were later installed after the initial installation.
  * Added "export PATH" statement to give the built-in binaries higher priority than the equivalent Entware binaries.
  * Miscellaneous code improvements & fine-tuning.

### v 2.0.6 - 22-Sep-2024 ###
  * Fixed error when loading the webGUI page on the latest 3006.102.xx F/W version.
  * Fixed "missing scrollbar" issue on browser windows when the webGUI page was loaded on the latest 3004.386.14 F/W version.
  * Fixes and improvements when reading and checking for configuration settings.
  * Removed/modified code related to "var $j = jQuery.noConflict();" which is now considered obsolete.

### v 2.0.5 - 11-Feb-2024 ###
  * Hotfix posted to address iCloud "weird server reply" issue. Only required if you are using iCloud/me.com SMTP services.

### v 2.0.4 - 31-Dec-2021 ###
  * End-of-year-housekeeping: this update includes minor updates to charts, interface id, and uninstall functions.

### v 2.0.3 - 27-Dec-2021 ###
  * The primary change is to check for amtm messaging existence. If available, vnStat-on-Merlin will use amtm messaging preferentially.
    - If amtm messaging is not configured, will continue to use Diversion (for now; see below).
    Notes:
    - The Diversion requirement is now deprecated in vnStat-on-Merlin R2. In a future update (TBD), only amtm messaging will be supported. This change is only for R2.

### v 2.0.2 - 27-Sep-2021 ###
  * Minor fix to the email symlinks to address an email piggybacking change.
    - More details here: https://www.snbforums.com/goto/post?id=715523

 ### v 2.0.1 - 16-Aug-2021 ###
* Minor fixes and addition of trend lines.
    - Includes the fix for the "month start" issue: remove "month start" field from monthly usage metrics. See notes here: https://www.snbforums.com/goto/post?id=707598.
    - With this version, there is a new feature: trend lines. These are found in the interactive charts on the R2vnStat-on-Merlin UI page, and show trends in data usage over time - both download and upload.
    - More information here: https://www.snbforums.com/goto/post?id=707674
      
### v 2.0.0 - 18-Jul-2021 ###

* Moves supported router architectures (ARM and AARCH) to vnStat 2.x.
  - Upgrade to vnStat 2.x branch (v 2.7 at release of R2)
  - Data usage is reported in megabytes (base-1000), so no correction is necessary to monitor against ISP bandwidth usage
  - Minor changes in the built-in charts, including a "shadow" to the daily and monthly usage with projected usage
  - Interactive charts created by Jack Yaz
        - Data usage, by minutes, hours and days
        - Data use comparisons (current week vs previous week, by day of week)
        - Data use trends (current week, previous week, two weeks prior) -
  - Minor changes to the text-based daily reports. These now focus on the most recent periods (last day, previous week, recent 6 months) and include yearly use.
  - Option to save data/configurations to USB rather than JFFS

        
# Version R1 (based on vnStat 1.18) #

### v 1.0.3 - 28-Dec-2021 ###
  * Fix for "false update" message that may show for vnStat-on-Merlin if you update to amtm 3.2.1.
    - You may be shown that v 2.0.3 is available, but when you attempt to update you are informed - correctly - that the 1.0.2 version is the latest. You should ignore this update prompt in 3.2.1. The R1 update to 1.0.3 appears to fix this notification.
    - Other minor configuration, performance and back-end tweaks to charts.

### v 1.0.2 - 11-Jul-2021 ###
* Minor fixes to correct an error which manifested itself as an "arithmetic error"; additional hot-fix to mitigate a related error.

### v 1.0.1 - 11-Apr-2021 ###
* New format for monthly total in output listing: i.e., `yyyy-mm (dd)` where dd is the start of the cycle in a given period
* Add "Router Friendly Name" to email subject line (can be modified in Diversion email set-up)
* Add cycle (re)start day to usage string: i.e., "You have used XX % (YY GB) of your ZZ GB cycle allowance, __the cycle starts on day 1 of the month__"
* Back-end: Always specify interface (-i) with vnstat commands in case database has multiple interfaces tracked

### v 1.0.0 - 28-Mar-2021 ###
* Release 1 (R1)
* Fix calculation for data-limits to reflect GB/TB (base 1000) - vnStat measures in GiB/TiB (base 1024)
  - More information: https://github.com/de-vnull/vnstat-on-merlin/blob/main/more-info.md#Units
* Add current use % to HTML and plain-text daily email; promote this information into the monthly use section
* General JY script enhancements (section headers, locks)
* UI updates (re-ordering, remove requirement for hard refresh, javascript improvements); additional UI options
* Additional under-the-hood optimizations, including:
  - Conversion code for unit change in CLI, scale data allowance when changing unit
  - Updated defaults for vnstat.conf (please check against any existing vnstat.conf)
  - Programming improvements (using --json for monthly data calculation, grep improvements, jq filter for WAN)
  - Make sure libjpeg-turbo is installed (note: library not available for MIPS, ignore any messages on MIPS)

### v 0.9.5 - 16-Mar-2021 ###
* Beta 3/RC1
* Many under-the-hood optimizations to improve reliability, accuracy and functionality based on Beta 2 feedback
* Added user-specified data limits: check vnstat-reported data use against a user-set limit
  - __Of particular interest to those with data caps__, e.g., Comcast, Cox, others
  - Data-limit monitoring with:
    - Optional email notification when reach 75%, 90% and 100% of data -limit
    - Data use warning message on UI page (75% and higher)
  - Data-limit calculations - UI and CLI menu (% data limit used)
  - CLI menu- and UI-updatable
  - Selectable GB or TB limits
* Expanded UI settings options
* Self-contained emailer (leverages Diversion credentials, but no longer calls separate script)
* Automatically backup existing vnstat databases (if found) during initial and full re-install
* Deprecate the "CLI daily total" graphic in favor of textual view (updates every 5 minutes; daily summary emailed at 23:59 local, if enabled)

### v 0.9.4 - 02-Mar-2021 ###
* Expanded CLI menu options (some deployed as mimimal updates/hotfixes)
* CLI menu option to enable editing of vnstat.conf
* UI updates, including defaulting to "AsusWRT color theme"
* Universal date reformatting (deployed as hotfix, for new or full re-installs only)
* Inclusion in AMTM (`amtm`) menu (AMTM version 3.1.9 and later) - the first beta add-on included in AMTM!

### v 0.9.3 - 27-Feb-2021 ###
* Beta 2 version, public deployment
* With _JackYaz_ install script
* Automated removal of manual/alpha/beta 1 installs (cleans up any scripts and cron jobs created by pre-beta 2 installations)
* Introduces CLI menu (`/jffs/scripts/dn-vnstat`) with configuration options (limited number of options, but includes removal)

### v 0.9.2 - Date not applicable ###
* Internal development version, not distrubuted publicly; collaboration initiated with _JackYaz_

### v 0.9.1 - 15-Feb-2021 ###
* Addition of div-email option (script from _elorimer_), which leverages Diversion's encrypted email functionality (with permission of _thelonelycoder_)
* Email support for daily usage email (contains day, week, monthly usage)
* Install script removed due to conflicts
* Revert to manual install steps
* Minor UI updates and tweaks

### v 0.9.0 - 08-Feb-2021 ###
* Beta 1 version, public deployment
* With partial install script support script by _Martineau_

### v 0.0.1 - 06-Feb-2021 ###
* Alpha/"how-to" manual install
* Initial version, designed for personal use
* Uses _JackYaz_ scaffolding from connmon (with permission and support from _JackYaz_)
