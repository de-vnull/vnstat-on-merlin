#!/bin/sh
# ver=1.0.0
# This script is used to refresh the daily/weekly/monthly vnstati - images - usage for the Vnstat on Merlin UI - by dev_null at snbforums
# Adapted from http://code.google.com/p/x-wrt/source/browse/trunk/package/webif/files/www/cgi-bin/webif/graphs-vnstat.sh
# mkdir /www/user/vnstat && cp /jffs/scripts/vnstat.htm /www/user/vnstat/vnstat.htm # not needed for Vnstat on Merlin
logger -s -t vnstats vnstati updating stats for UI
vnstat -u
#
WWW_D=/www/user/vnstat # output images to here
LIB_D=/opt/var/lib/vnstat # db location - verify matches your install
BIN=/opt/bin/vnstati  # which vnstati - verify matches your install
#
outputs="s h d t m hs"   # what images to generate
#
# Sanity checks
[ -d "$WWW_D" ] || mkdir -p "$WWW_D" # make the folder if it dont exist.
#
# You might want to setup a link if it dont exist.
# [ -L /www/vnstat ] || ln -sf /www/vnstat /www/user/
# was /tmp/www/
#
# End of config changes
interfaces="eth0"
# was "$(ls -1 $LIB_D)"
#
if [ -z "$interfaces" ]; then
    echo "No database found, nothing to do."
    echo "A new database can be created with the following command: "
    echo "    vnstat -u -i eth0"
    exit 0
else
    for interface in $interfaces ; do
        for output in $outputs ; do
            $BIN -${output} -i $interface -o $WWW_D/vnstat_${interface}_${output}.png
        done
    done
fi
#
exit 1
