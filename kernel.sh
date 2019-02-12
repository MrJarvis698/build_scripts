#!/bin/bash

# Telegram
export ROL=~/build_scripts/onememe.conf

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
export SUBVER=$(grep "SUBLEVEL =" < Makefile | awk '{print $3}')

# Name of zip
export ZIP=IllusionKernel-$SUBVER-$BUILDDATE-$BUILDTIME

# Log
rm -rf log*.txt
#telegram-send --config $ROL --format html "Logging to file <code>log-$BUILDDATE-$BUILDTIME.txt</code>"
export LOGFILE=log-$BUILDDATE-$BUILDTIME.txt

# Bring up-to-date with sauce
git pull

# Clang and GCC
export CC="$(command -v ccache) /home/anirudhgupta109/clang/clang-r349610/bin/clang"
export KBUILD_COMPILER_STRING="$(${CC} --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g')"
export CROSS_COMPILE=/home/anirudhgupta109/gcc/bin/aarch64-linux-android-
export CLANG_TRIPLE=aarch64-linux-gnu-
export ARCH=arm64
export SUBARCH=arm64

# installclean
#telegram-send --config $ROL --format html "Building Clean af"
rm -rf out/arch/arm64/boot/Image.gz-dtb
#rm -rf out/

# Activate venv
source ~/tmp/venv/bin/activate

# Build
make O=out $DEFCONFG && time make -j$(nproc --all) O=out | tee $LOGFILE
EXITCODE=$?
if [ $EXITCODE -ne 0 ]; then telegram-send --config $ROL --format html "Build failed! Check log file <code>$LOGFILE</code>"; telegram-send --config $ROL --file $LOGFILE; exit 1; fi

# Move Image.gz-dtb to AGKernel Folder
rm -rf $COMPRESS/Image.gz-dtb
cp out/arch/arm64/boot/Image.gz-dtb $COMPRESS/
cd $COMPRESS
zip $ZIP -r *

# Starting upload!
telegram-send --config $ROL --file $ZIP.zip --timeout 480.0
mv $ZIP.zip $OUTPUT/$ZIP.zip
cd $OUTPUT
git push
cd $SAUCE
telegram-send --config $ROL --file out/include/generated/compile.h
