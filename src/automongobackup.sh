#!/bin/bash
set -eo pipefail
#
# MongoDB Backup Script
# VER. 0.20
# More Info: http://github.com/micahwedemeyer/automongobackup

# Note, this is a lobotomized port of AutoMySQLBackup
# (http://sourceforge.net/projects/automysqlbackup/) for use with
# MongoDB.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
#=====================================================================
#=====================================================================
# Set the following variables to your system needs
# (Detailed instructions below variables)
#=====================================================================

# Database name to specify a specific database only e.g. myawesomeapp
# Unnecessary if backup all databases
# DBNAME=""

# Username to access the mongo server e.g. dbuser
# Unnecessary if authentication is off
# DBUSERNAME=""

# Password to access the mongo server e.g. password
# Unnecessary if authentication is off
# DBPASSWORD=""

# Database for authentication to the mongo server e.g. admin
# Unnecessary if authentication is off
# DBAUTHDB=""

# Host name (or IP address) of mongo server e.g localhost
DBHOST="127.0.0.1"

# Port that mongo is listening on
DBPORT="27017"

# Backup directory location e.g /backups
BACKUPDIR="/var/backups/mongodb"

# ============================================================================
# === SCHEDULING AND RETENTION OPTIONS ( Read the doc's below for details )===
#=============================================================================

# Do you want to do daily backups? How long do you want to keep them?
DODAILY="yes"
DAILYRETENTION=0

# Which day do you want weekly backups? (1 to 7 where 1 is Monday)
DOWEEKLY="yes"
WEEKLYDAY=6
WEEKLYRETENTION=4

# Do you want monthly backups? How long do you want to keep them?
DOMONTHLY="yes"
MONTHLYRETENTION=4

# ============================================================
# === ADVANCED OPTIONS ( Read the doc's below for details )===
#=============================================================

# Choose Compression type. (gzip or bzip2)
COMP="gzip"

# Additionally keep a copy of the most recent backup in a seperate directory.
LATEST="yes"

# Make Hardlink not a copy
LATESTLINK="yes"

# Use oplog for point-in-time snapshotting.
OPLOG="yes"

# Allow DBUSERNAME without DBAUTHDB
REQUIREDBAUTHDB="yes"

# Maximum files of a single backup used by split - leave empty if no split required
# MAXFILESIZE=""

# If defined used as a key for symmetric encryption of the resulting backup file
# ENCRYPTION_KEY=

# Command to run before backups (uncomment to use)
# PREBACKUP=""

# Command run after backups (uncomment to use)
# POSTBACKUP=""

#=====================================================================
# Options documentation
#=====================================================================
# Set DBUSERNAME and DBPASSWORD of a user that has at least SELECT permission
# to ALL databases.
#
# Set the DBHOST option to the server you wish to backup, leave the
# default to backup "this server".(to backup multiple servers make
# copies of this file and set the options for that server)
#
# You can change the backup storage location from /backups to anything
# you like by using the BACKUPDIR setting..
#
# Finally copy automongobackup.sh to anywhere on your server and make sure
# to set executable permission. You can also copy the script to
# /etc/cron.daily to have it execute automatically every night or simply
# place a symlink in /etc/cron.daily to the file if you wish to keep it
# somwhere else.
#
# NOTE: On Debian copy the file with no extention for it to be run
# by cron e.g just name the file "automongobackup"
#
# Thats it..
#
#
# === Advanced options ===
#
# To set the day of the week that you would like the weekly backup to happen
# set the WEEKLYDAY setting, this can be a value from 1 to 7 where 1 is Monday,
# The default is 6 which means that weekly backups are done on a Saturday.
#
# Use PREBACKUP and POSTBACKUP to specify Pre and Post backup commands
# or scripts to perform tasks either before or after the backup process.
#
#
#=====================================================================
# Backup Rotation..
#=====================================================================
#
# Daily backups are executed if DODAILY is set to "yes".
# The number of daily backup copies to keep for each day (i.e. 'Monday', 'Tuesday', etc.) is set with DAILYRETENTION.
# DAILYRETENTION=0 rotates daily backups every week (i.e. only the most recent daily copy is kept). -1 disables rotation.
#
# Weekly backups are executed if DOWEEKLY is set to "yes".
# WEEKLYDAY [1-7] sets which day a weekly backup occurs when cron.daily scripts are run.
# Rotate weekly copies after the number of weeks set by WEEKLYRETENTION.
# WEEKLYRETENTION=0 rotates weekly backups every week. -1 disables rotation.
#
# Monthly backups are executed if DOMONTHLY is set to "yes".
# Monthy backups occur on the first day of each month when cron.daily scripts are run.
# Rotate monthly backups after the number of months set by MONTHLYRETENTION.
# MONTHLYRETENTION=0 rotates monthly backups upon each execution. -1 disables rotation.
#
#=====================================================================
# Please Note!!
#=====================================================================
#
# I take no resposibility for any data loss or corruption when using
# this script.
#
# This script will not help in the event of a hard drive crash. You
# should copy your backups offline or to another PC for best protection.
#
# Happy backing up!
#
#=====================================================================
# Restoring
#=====================================================================
# ???
#
#=====================================================================
# Change Log
#=====================================================================
# VER 0.10 - (2015-06-22) (author: Markus Graf)
#        - Added option to backup only one specific database
#
# VER 0.9 - (2011-10-28) (author: Joshua Keroes)
#       - Fixed bugs and improved logic in select_secondary_member()
#       - Fixed minor grammar issues and formatting in docs
#
# VER 0.8 - (2011-10-02) (author: Krzysztof Wilczynski)
#       - Added better support for selecting Secondary member in the
#         Replica Sets that can be used to take backups without bothering
#         busy Primary member too much.
#
# VER 0.7 - (2011-09-23) (author: Krzysztof Wilczynski)
#       - Added support for --journal dring taking backup
#         to enable journaling.
#
# VER 0.6 - (2011-09-15) (author: Krzysztof Wilczynski)
#       - Added support for --oplog during taking backup for
#         point-in-time snapshotting.
#       - Added filter for "mongodump" writing "connected to:"
#         on the standard error, which is not desirable.
#
# VER 0.5 - (2011-02-04) (author: Jan Doberstein)
#       - Added replicaset support (don't Backup on Master)
#       - Added Hard Support for 'latest' Copy
#
# VER 0.4 - (2010-10-26)
#       - Cleaned up warning message to make it clear that it can
#         usually be safely ignored
#
# VER 0.3 - (2010-06-11)
#       - Added the DBPORT parameter
#       - Changed USERNAME and PASSWORD to DBUSERNAME and DBPASSWORD
#       - Fixed some bugs with compression
#
# VER 0.2 - (2010-05-27) (author: Gregory Barchard)
#       - Added back the compression option for automatically creating
#         tgz or bz2 archives
#       - Added a cleanup option to optionally remove the database dump
#         after creating the archives
#       - Removed unnecessary path additions
#
# VER 0.1 - (2010-05-11)
#       - Initial Release
#
# VER 0.2 - (2015-09-10)
#	- Added configurable backup rentention options, even for
# 	  monthly backups.
#
#=====================================================================
#=====================================================================
#=====================================================================
#
# Should not need to be modified from here down!!
#
#=====================================================================
#=====================================================================
#=====================================================================

shellout () {
    if [ -n "$1" ]; then
        echo "$1"
        exit 1
    fi
    exit 0
}

# External config - override default values set above
for x in default sysconfig; do
  if [ -f "/etc/$x/automongobackup" ]; then
      source /etc/$x/automongobackup
  fi
done

# Include extra config file if specified on commandline, e.g. for backuping several remote dbs from central server
[ ! -z "$1" ] && [ -f "$1" ] && source ${1}

#=====================================================================

PATH=/usr/local/bin:/usr/bin:/bin
DATE=$(date +%Y-%m-%d_%Hh%Mm)                      # Datestamp e.g 2002-09-21
DOW=$(date +%A)                                    # Day of the week e.g. Monday
DNOW=$(date +%u)                                   # Day number of the week 1 to 7 where 1 represents Monday
DOM=$(date +%d)                                    # Date of the Month e.g. 27
M=$(date +%B)                                      # Month e.g January
W=$(date +%V)                                      # Week Number e.g 37
VER=0.10                                          # Version Number
OPT=""                                            # OPT string for use with mongodump

# Do we need to use a username/password?
if [ "$DBUSERNAME" ]; then
    OPT="$OPT --username=$DBUSERNAME --password=$DBPASSWORD"
    if [ "$REQUIREDBAUTHDB" = "yes" ]; then
        OPT="$OPT --authenticationDatabase=$DBAUTHDB"
    fi
fi

# Do we use oplog for point-in-time snapshotting?
if [ "$OPLOG" = "yes" ]; then
    OPT="$OPT --oplog"
fi

# Do we need to backup only a specific database?
if [ "$DBNAME" ]; then
  OPT="$OPT -d $DBNAME"
fi

# Create required directories
mkdir -p $BACKUPDIR/{daily,weekly,monthly} || shellout 'failed to create directories'

if [ "$LATEST" = "yes" ]; then
    rm -rf "$BACKUPDIR/latest"
    mkdir -p "$BACKUPDIR/latest" || shellout 'failed to create directory'
fi

# Functions

if [ -n "$MAXFILESIZE" ]; then
    write_file() {
        split --bytes "$MAXFILESIZE" --numeric-suffixes - "${1}-"
    }
else
    write_file() {
        cat > "$1"
    }
fi

SUFFIX=".archive"

if [ -n "$COMP" ]; then
    [ "$COMP" = "gzip" ] && SUFFIX="${SUFFIX}.gz"
    [ "$COMP" = "bzip2" ] && SUFFIX="${SUFFIX}.bz2"
    [ "$COMP" = "xz" ] && SUFFIX="${SUFFIX}.xz"
    compress() {
        $COMP ${COMP_OPTS} --stdout
    }
else
    compress() { cat; }
fi

if [ -n "$ENCRYPTION_KEY" ]; then
    SUFFIX="${SUFFIX}.gpg"
    encrypt() {
        /usr/bin/gpg --symmetric --passphrase "$ENCRYPTION_KEY" --batch --no-use-agent
    }
else
    encrypt() { cat; }
fi

archive() {
    mongodump --quiet --host=$DBHOST --port=$DBPORT --archive $OPT
}

# Compression function plus latest copy
dbdump() {
    dir=$(dirname "$1")
    file=$(basename "$1")
    echo Dump to "${file}${SUFFIX}"
    cd "$dir" || return 1
    archive | compress | encrypt | write_file "${file}${SUFFIX}"
    cd - >/dev/null || return 1

    if [ "$LATEST" = "yes" ]; then
        if [ "$LATESTLINK" = "yes" ];then
            COPY="ln"
        else
            COPY="cp"
        fi
        $COPY "$1$SUFFIX*" "$BACKUPDIR/latest/"
    fi

    return 0
}

# Run command before we begin
if [ "$PREBACKUP" ]; then
    echo ======================================================================
    echo "Prebackup command output."
    echo
    eval "$PREBACKUP"
    echo
    echo ======================================================================
    echo
fi

# Hostname for LOG information
if [ "$DBHOST" = "localhost" ] || [ "$DBHOST" = "127.0.0.1" ]; then
    HOST=$(hostname)
    if [ "$SOCKET" ]; then
        OPT="$OPT --socket=$SOCKET"
    fi
else
    HOST=$DBHOST
fi

echo ======================================================================
echo AutoMongoBackup VER $VER

echo
echo Backup of Database Server - $HOST on $DBHOST
echo ======================================================================

echo Backup Start "$(date)"
echo ======================================================================
# Monthly Full Backup of all Databases
if [[ $DOM = "01" ]] && [[ $DOMONTHLY = "yes" ]]; then
    echo Monthly Full Backup
    echo
    # Delete old monthly backups while respecting the set rentention policy.
    if [[ $MONTHLYRETENTION -ge 0 ]] ; then
        NUM_OLD_FILES=$(find $BACKUPDIR/monthly -depth -not -newermt "$MONTHLYRETENTION month ago" -type f | wc -l)
        if [[ $NUM_OLD_FILES -gt 0 ]] ; then
            echo Deleting "$NUM_OLD_FILES" global setting backup file\(s\) older than "$MONTHLYRETENTION" month\(s\) old.
	    find $BACKUPDIR/monthly -not -newermt "$MONTHLYRETENTION month ago" -type f -delete
        fi
    fi
    FILE="$BACKUPDIR/monthly/$DATE.$M"

# Weekly Backup
elif [[ $DNOW = "$WEEKLYDAY" ]] && [[ $DOWEEKLY = "yes" ]] ; then
    echo Weekly Backup
    echo
    if [[ $WEEKLYRETENTION -ge 0 ]] ; then
        # Delete old weekly backups while respecting the set rentention policy.
        NUM_OLD_FILES=$(find $BACKUPDIR/weekly -depth -not -newermt "$WEEKLYRETENTION week ago" -type f | wc -l)
        if [[ $NUM_OLD_FILES -gt 0 ]] ; then
            echo Deleting "$NUM_OLD_FILES" global setting backup file\(s\) older than "$WEEKLYRETENTION" week\(s\) old.
            find $BACKUPDIR/weekly -not -newermt "$WEEKLYRETENTION week ago" -type f -delete
        fi
    fi
    FILE="$BACKUPDIR/weekly/week.$W.$DATE"

# Daily Backup
elif [[ $DODAILY = "yes" ]] ; then
    echo Daily Backup of Databases
    echo
    # Delete old daily backups while respecting the set rentention policy.
    if [[ $DAILYRETENTION -ge 0 ]] ; then
        NUM_OLD_FILES=$(find $BACKUPDIR/daily -depth -name "*.$DOW.*" -not -newermt "$DAILYRETENTION week ago" -type f | wc -l)
        if [[ $NUM_OLD_FILES -gt 0 ]] ; then
            echo Deleting "$NUM_OLD_FILES" global setting backup file\(s\) made in previous weeks.
            find $BACKUPDIR/daily -name "*.$DOW.*" -not -newermt "$DAILYRETENTION week ago" -type f -delete
        fi
    fi
    FILE="$BACKUPDIR/daily/$DATE.$DOW"

fi

dbdump "$FILE"

STATUS=$?

echo ----------------------------------------------------------------------
echo Backup End Time "$(date)"
echo ======================================================================

echo Total disk space used for backup storage..
echo Size - Location
du -hs "$BACKUPDIR"
echo
echo ======================================================================

# Run command when we're done
if [ "$POSTBACKUP" ]; then
    echo ======================================================================
    echo "Postbackup command output."
    echo
    eval "$POSTBACKUP"
    echo
    echo ======================================================================
fi

exit $STATUS
