#!/bin/bash

# Build related
export DEFCONFG=kronic_defconfig

# Telegram Chat ID and Bot API key
export ROL=~/build_scripts/onememe.conf

# Path defines
export SAUCE=/home/anirudhgupta109/mainline/linux
export OUTPUT=/home/anirudhgupta109/mainline
export ARCHIVES=/home/anirudhgupta109/ROMs

# Date and time
export BUILDDATE=$(date +%d%m)
export BUILDTIME=$(date +%H%M)

# Tell everyone we are going to start building
cd $SAUCE

# Naming stuffs
export TRUE=1
export FALSE=0

export SERVER=1
export VER=$(grep "VERSION =" < Makefile -w | awk '{print $3}')
export PATCHLVL=$(grep "PATCHLEVEL =" < Makefile | awk '{print $3}')
export SUBVER=$(grep "SUBLEVEL =" < Makefile | awk '{print $3}')
export LOCALVER="-IllusionKernel"
export COMMIT=$(git rev-parse --short=8 HEAD)

# Name of zip
export NAME=Illusion-${VER}_${PATCHLVL}_${SUBVER}-$COMMIT-$BUILDDATE-$BUILDTIME

# Log
rm -rf log*.txt
export LOGFILE=log-$BUILDDATE-$BUILDTIME.txt

# Bring up-to-date with sauce
git pull

# installclean
make clean
make mrproper
make $DEFCONFG
rm -rf $OUTPUT/linux-*.deb

# Build
export DATE_START=$(date +"%s")
if [[ $SERVER == $TRUE ]]; then
    make CC="ccache gcc" HOSTCC='ccache gcc' ARCH=x86 SUBARCH=x86_64 -j$(nproc --all) bindeb-pkg
    cd $OUTPUT
    zip $NAME -r linux*.deb -x *dbg*
    while [[ ! "$DLURL" =~ "https://drive.google.com" ]]; do
        gdrive upload $NAME.zip | tee -a /tmp/gdrive-$BUILDDATE-$BUILDTIME
        FILEID=$(cat /tmp/gdrive-$BUILDDATE-$BUILDTIME | tail -n 1 | awk '{ print $2 }')
        gdrive share $FILEID
        gdrive info $FILEID | tee -a /tmp/gdrive-info-$BUILDDATE-$BUILDTIME
        MD5SUM=$(cat /tmp/gdrive-info-$BUILDDATE-$BUILDTIME | grep 'Md5sum' | awk '{ print $2 }')
        NAME=$(cat /tmp/gdrive-info-$BUILDDATE-$BUILDTIME | grep 'Name' | awk '{ print $2 }')
        SIZE=$(cat /tmp/gdrive-info-$BUILDDATE-$BUILDTIME | grep 'Size' | awk '{ print $2 }')
        DLURL=$(cat /tmp/gdrive-info-$BUILDDATE-$BUILDTIME | grep 'DownloadUrl' | awk '{ print $2 }')
    done
    echo -e "Linux Kernel! \nKernel details: <code>$NAME</code>\nFile ID: <code>$FILEID</code>\nSize: <code>$SIZE</code>MB\nmd5sum: <code>$MD5SUM</code>\nDownload link: $DLURL" | telegram-send --config $ROL --format html --stdin
    mv $NAME.zip $ARCHIVES
    cd $SAUCE
    sudo shutdown 10
else
    make CC="ccache gcc" HOSTCC='ccache gcc' ARCH=x86 SUBARCH=x86_64 -j$(nproc --all)
    sudo make modules_install -j$(nproc --all)
    sudo make install -j$(nproc --all)
    sudo update-initramfs -c -k "$VER.$PATCHLVL.$SUBVER$LOCALVER"
    sudo update-grub
fi
export DATE_END=$(date +"%s")
export DATE_DIFF="$(bc <<<"${DATE_END} - ${DATE_START}")"
echo -e "Finished build of $NAME"
echo -e "Time: $(bc <<<"${DATE_DIFF} / 60") minute(s) and $(bc <<<"${DATE_DIFF} % 60") seconds."
