### More information - vnStat-on-Merlin ###

# Release versions - R1 and R2 #

* R1 is the original vnStat-on-Merlin, which uses vnstat version 1.18, and is available for all platforms (MIPs, ARM, AARCH64). A legacy branch will provide support for MIPs routers but all others will be migrated to R2.
* R2 is the update to vnStat-on-Merlin, and uses vnstat version 2.x, but is available only for ARM and AARCH64. This will become the primary branch for all other supported routers.

# Data-limits

The information that is reported by vnStat (and therefore vnStat-on-Merlin) regarding data use should be considered a guide - an approximation of actual use. The application vnStat reports totals that may or may not be equivalent to those recorded by your provider, may start and/or stop on a different date, and/or be affected by variables such as hardware acceleration, router settings that bypass the TCP/IP stack, or even by scheduled reboots. The user must conduct proper due diligence to determine if the usage reported by vnStat aligns with your provider. The user assumes all responsibility for the use of the information provided by vnStat and vnStat-on-Merlin.

* This number should be entered in gigabytes (GB) or terabytes (TB) - base 1000. See `Units` below.

# Units

## Release 1 (R1):
The units reported by vnstat 1.18, upon which vnStat-on-Merlin (beta 2 through R1) is based, calculate using IEC standards (MiB/GiB) - base-1024 -, which differs slightly from GB/TB typically used by ISPs, which is base-1000. There is a setting in `vnstat.conf` ("UnitMode") which allows the user to change the preferred unit, __but no recalculation is performed__. This has been confirmed verified by the author of vnStat (Teemu Toivola).

The `Bandwidth allowance` should be entered as __GB/TB__, and the calculations for `Data usage for current month` against the data limit is calculated in GB/TB (base 1000), by leveraging the underlying vnstat totals and multiplying accordingly. 

## Release 2 (R2):

The units reported by vnstat 2.6, upon which vnstat-on-Merlin R2 is based, calculate usage in base-1000, which is what ISP data counts typically use. Therefore no additional calculation step is required to properly display GB/TB usage in R2.

# MonthRotate

* In a post, the author of vnStat (Teemu Toivola) provied more detail on the `MonthRotate` setting found in vnstat.conf:

  "_If MonthRotate has a value of 1 then the month obviously changes on the first day of every month._ [Note: This is the default install setting, and is correct for Comcast customers.]
  
  "_If you give it, for example, a value of 10 then the month would change on the 10th day. However, from vnStat point of view, when you make that change the month can't already be the ongoing month or otherwise you aren't going to see any change until the next month. As an example, if in January I'd set MonthRotate to 10 then vnStat would continue showing January until it's the 10th of February._ 

  "_If I'd change the value from 10 to 1 on the 3rd of February then I'd right away get vnStat to start counting for February. So increasing the MonthRotate value results in the change being visible only during the next month if the current day of month was equal or greater than the previous value. Decreasing the MonthRotate value results in the month to change if the new value is less or equal to the current day of month."_

* Therefore, for this setting, changing the date during the month will typically not result in any observable change until that date in the __following month__.
* The example in paragraph 2, the "month" reported will be the month at the start of the cycle, _January_, and will continue to report usage as _January_ until the _10th of February_ (calendar date). It will then report usage as _February_ until the _10th of March_ (calendar date).
* The example in paragraph 3, the "month" reported will be the February, but some usage may have already been accounted for as _January_ and therefore the totals for _February_ may not be accurate.
* You should consider the usage as the __start of the cycle__ rather than __end of cycle__, which may be more familiar billing- and accountability-wise.
* In the United States, Comcast/Xfinity begins measurement on the 1st of the month in all markets, so no adjustment from the default is required.

# Time-output-mode #

* Placeholder.
