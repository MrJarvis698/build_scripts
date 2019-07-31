#!/bin/bash

# ccache
export USE_CCACHE=1

# Telegram Chat ID and Bot API key
export ROL=~/build_scripts/onememe.conf
export AOSIP=~/build_scripts/aosip.conf

# Google Drive for Linux
#export GDRIVE=/usr/bin/gdrive

# Build related
export TARGET=aosip_fajita-userdebug
export AOSIPVER=9.0
export DEVICENAME=fajita
export MAKETARGET=kronic

# Go to source directory
cd ~/aosip

#telegram-send --config $ROL --format html "Deleting old logs now"
rm -rf log*.txt

# AOSiP Build Type
export AOSIP_BUILDTYPE=CI

# Date and time
export BUILDDATE=$(date +%Y%m%d)
export BUILDTIME=$(date +%H%M)

# Tell everyone we are going to start building
telegram-send --config $ROL --format html "Starting build (<code>AOSiP-$AOSIPVER-$AOSIP_BUILDTYPE-$DEVICENAME-$BUILDDATE</code>)"

# Log
export LOGFILE=log-$BUILDDATE-$BUILDTIME.txt

# Repo sync
#repo sync -f --force-sync --no-tags --no-clone-bundle -c

# envsetup
source build/envsetup.sh

# repopick
#bash repopick.sh

# lunch
lunch $TARGET

# installclean
rm -rf out/target/product/

export ROMZ=AOSiP-$AOSIPVER-$AOSIP_BUILDTYPE-$DEVICENAME-$BUILDDATE

# Build
time mka $MAKETARGET -j$(nproc --all) | tee ./$LOGFILE
EXITCODE=$?
if [ $EXITCODE -ne 0 ]; then telegram-send --config $ROL --format html "Build failed! Check log file <code>$LOGFILE</code>"; telegram-send --config $ROL --file $LOGFILE; exit 1; fi

# Move zip to ROMs Folder
mv $OUT/$ROMZ.zip /home/anirudhgupta109/ROMs/$ROMZ.zip
export STO=/home/anirudhgupta109/ROMs

# Starting upload!
while [[ ! "$DLURL" =~ "https://drive.google.com" ]]; do
    gdrive upload ~/ROMs/$ROMZ.zip | tee -a /tmp/gdrive-$BUILDDATE-$BUILDTIME
    FILEID=$(cat /tmp/gdrive-$BUILDDATE-$BUILDTIME | tail -n 1 | awk '{ print $2 }')
    gdrive share $FILEID
    gdrive info $FILEID | tee -a /tmp/gdrive-info-$BUILDDATE-$BUILDTIME
    MD5SUM=$(cat /tmp/gdrive-info-$BUILDDATE-$BUILDTIME | grep 'Md5sum' | awk '{ print $2 }')
    NAME=$(cat /tmp/gdrive-info-$BUILDDATE-$BUILDTIME | grep 'Name' | awk '{ print $2 }')
    SIZE=$(cat /tmp/gdrive-info-$BUILDDATE-$BUILDTIME | grep 'Size' | awk '{ print $2 }')
    DLURL=$(cat /tmp/gdrive-info-$BUILDDATE-$BUILDTIME | grep 'DownloadUrl' | awk '{ print $2 }')
done
#rsync -e ssh ~/ROMs/$ROMZ.zip anirudhgupta109@frs.sourceforge.net:/home/frs/project/agbuilds/Fajita/AOSiP
echo "{ \"response\": [ { \"datetime\": $(grep ro\.build\.date\.utc $OUT/system/build.prop | cut -d= -f2), \"filename\": \"$(basename $(ls $STO/$ROMZ.zip))\", \"id\": \"$((sha256sum $STO/$ROMZ.zip) | cut -d ' ' -f1)\", \"romtype\": \"$AOSIP_BUILDTYPE\", \"size\": $(stat -c%s $STO/$ROMZ.zip), \"url\": \"https://sourceforge.net/projects/agbuilds/files/Fajita/AOSiP/$(basename $(ls $STO/$ROMZ.zip))/download\", \"version\": \"9.0\"  }]}" > sysserv.json
jq . sysserv.json
echo -e "「Build completed! 」\nPackage name: <code>$NAME</code>\nFile ID: <code>$FILEID</code>\nSize: <code>$SIZE</code>MB\nmd5sum: <code>$MD5SUM</code>\nDownload link: $DLURL" | telegram-send --config $ROL --format html --stdin
echo -e "「Build completed! 」\nPackage name: <code>$NAME</code>\nFile ID: <code>$FILEID</code>\nSize: <code>$SIZE</code>MB\nmd5sum: <code>$MD5SUM</code>\nDownload link: $DLURL" | telegram-send --config $AOSIP --format html --stdin
telegram-send --config $ROL --file sysserv.json
telegram-send --config $ROL --file $LOGFILE --timeout 40.0
telegram-send --config $ROL --format html "Shutting down server"
telegram-send --config $AOSIP "@nezorflame @ironhydee test pls"
sudo shutdown
