# Changelog #

### v 1.0.1 - 11-Apr-2021 ###
* New format for monthly total in output listing: i.e., `yyyy-mm (dd)` where dd is the start of the cycle in a given period
* Add "Router Friendly Name" to email subject line (can be modified in Diversion email set-up)
* Add cycle restart day to usage string: i.e., "You have used XX % (YY GB) of your ZZ GB cycle allowance, __the cycle starts on day 1 of the month__"
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
