# Changelog #

### v 0.9.5 - 16-Mar-2021 ###
* Beta 3/RC1
* Many under the hood optimizations to improve reliability, accuracy and functionality based on Beta 2 feedback
* Added user-specified data limits: check vnstat-reported data use against a user-specific limit
  - __Of particular interest to those with data caps__, e.g., Comcast, Cox, others
  - Data limit monitoring with:
    - Optional email notification when reach 75%, 90% and 100% of data limit
    - Data use warning message on UI page (75% and higher)
  - Data limit calculations - UI and menu (% data limit used)
  - CLI menu- and UI-updatable
  - Selectable GB or TB limits
* Expanded UI settings options
* Self-contained emailer (leverages Diversion credentials, but no longer calls separate script)
* Automatically backup existing vnstat databases (if found) during initial and full re-install
* Deprecate the "CLI daily total" graphic in favor of textual view (updates every 5 minutes; daily summary emailed at 23:59 local, if enabled)

### v 0.9.4 - 02-Mar-2021 ###
* Expanded menu options (some deployed as mimimal updates/hotfixes)
* Menu option to enable editing of vnstat.conf
* UI updates, including defaulting to "AsusWRT color theme"
* Universal date reformatting (deployed as hotfix, for new or full re-installs only)
* Inclusion in AMTM menu (AMTM version 3.1.9 and later) - the first beta add-on included in AMTM!

### v 0.9.3 - 27-Feb-2021 ###
* Beta 2 version, public deployment
* With _JackYaz_ install script
* Automated removal of manual/alpha/beta 1 installs (cleans up any scripts and cron jobs created by pre-beta 2 installations)
* Introduces menu of configuration options (limited number of options)

### v 0.9.1 - 15-Feb-2021 ###
* Addition of div-email option (script from _elorimer_), which leverages Diversion's encrypted email functionality (with permission of _thelonelycoder_)
* Install script removed due to conflicts
* Revert to manual install steps
* Minor UI updates and tweaks

### v 0.9.0 - 08-Feb-2021 ###
* Beta 1 version, public deployment
* With partial install script; preliminary support script by _Martineau_

### v 0.0.1 - 06-Feb-2021 ###
* Alpha/"how-to" manual install
* Initial version, designed for personal use
* Uses @JackYaz scaffolding from connmon (with permission and support from _JackYaz_)
