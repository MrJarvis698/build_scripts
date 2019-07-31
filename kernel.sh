#!/bin/bash

# Telegram
export ROL=~/build_scripts/onememe.conf
export IK=~/build_scripts/illusion.conf

# Build related
export DEVICENAME=enchilada
export DEFCONFG=kronic_defconfig

# Path defines
export SAUCE=/home/anirudhgupta109/priv
export COMPRESS=/home/anirudhgupta109/kernels/compress
export OUTPUT=/home/anirudhgupta109/kernels
export USE_CCACHE=1

# Date and time
export BUILDDATE=$(date +%d%m)
export BUILDTIME=$(date +%H%M)

# Tell everyone we are going to start building
cd $SAUCE

# Naming stuffs
export SUBVER=$(grep "SUBLEVEL =" < Makefile | awk '{print $3}')
export COMMIT=$(git rev-parse --short=8 HEAD)

# Name of zip
export ZIP=IllusionKernel-$SUBVER-$COMMIT-$BUILDDATE-$BUILDTIME

# Log
rm -rf log*.txt
#telegram-send --config $ROL --format html "Logging to file <code>log-$BUILDDATE-$BUILDTIME.txt</code>"
export LOGFILE=log-$BUILDDATE-$BUILDTIME.txt

# Bring up-to-date with sauce
git pull

# Clang and GCC paths
export CLANG="/home/anirudhgupta109/clang/clang-r353983e/bin/clang"
export GCC="/home/anirudhgupta109/gcc/bin/aarch64-linux-android-"
# Trim clang compiler string
export KBUILD_COMPILER_STRING="$(${CLANG} --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g')"

# installclean
#telegram-send --config $ROL --format html "Building Clean af"
rm -rf out/arch/arm64/boot/Image.gz-dtb
#rm -rf out/

# Activate venv
#source ~/tmp/venv/bin/activate

# Build
make O=out ARCH=arm64 $DEFCONFG && time make -j$(nproc --all) O=out ARCH=arm64 CC="$(command -v ccache) $CLANG" CLANG_TRIPLE=aarch64-linux-gnu- CROSS_COMPILE=$GCC | tee $LOGFILE
EXITCODE=$?
if [ $EXITCODE -ne 0 ]; then telegram-send --config $ROL --format html "Build failed! Check log file <code>$LOGFILE</code>"; telegram-send --config $ROL --file $LOGFILE; exit 1; fi

# Move Image.gz-dtb to AGKernel Folder
rm -rf $COMPRESS/Image.gz-dtb
cp out/arch/arm64/boot/Image.gz-dtb $COMPRESS/
cd $COMPRESS
zip $ZIP -r *

# Starting upload!
telegram-send --config $ROL --file $ZIP.zip --timeout 480.0
#telegram-send --config $IK --file $ZIP.zip --timeout 480.0
mv $ZIP.zip $OUTPUT/$ZIP.zip
cd $OUTPUT
git push
cd $SAUCE
telegram-send --config $ROL --file out/include/generated/compile.h
#sudo shutdown
