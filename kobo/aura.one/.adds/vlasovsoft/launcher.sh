#!/bin/sh

if [ -z "$VLASOVSOFT_KSM" ]; then
    export ROOT=/mnt/onboard/.adds/vlasovsoft
fi

LOG=/dev/null
# Uncomment to see log
# LOG=$ROOT/vlasovsoft.log.txt
PLATFORM=freescale
if [ `dd if=/dev/mmcblk0 bs=512 skip=1024 count=1 | grep -c "HW CONFIG"` == 1 ]; then
        CPU=`ntx_hwconfig -s -p /dev/mmcblk0 CPU`
        PLATFORM=$CPU-ntx
        WIFI=`ntx_hwconfig -s -p /dev/mmcblk0 Wifi`
fi
INTERFACE=wlan0
WIFI_MODULE=ar6000
if [ $PLATFORM != freescale ]; then
        INTERFACE=eth0
        WIFI_MODULE=dhd
        if [ x$WIFI == "xRTL8189" ]; then
            WIFI_MODULE=8189fs
        fi
fi
NAME=`/bin/kobo_config.sh 2>/dev/null` 
MODEL_NUMBER=$(cut -f 6 -d ',' /mnt/onboard/.kobo/version | sed -e 's/^[0-]*//')
case $NAME in
 alyssum)  DEVICE=GLOHD    ;;
 dahlia)   DEVICE=AURAH2O  ;;
 dragon)   DEVICE=AURAHD   ;;
 phoenix)  DEVICE=AURA     ;;
 kraken)   DEVICE=GLO      ;;
 trilogy)  DEVICE=TOUCH    ;;
 pixie)    DEVICE=MINI     ;;
 pika)     DEVICE=TOUCH2   ;;
 daylight) DEVICE=AURAONE  ;;
 star)     DEVICE=AURA2    ;;
 snow)

   case $MODEL_NUMBER in
     374) DEVICE=AURAH2O2_v1 ;;
     378) DEVICE=AURAH2O2_v2 ;;
     *)   DEVICE=TOUCH ;;
   esac
   ;;

 nova)     DEVICE=CLARAHD  ;;
 frost)    DEVICE=FORMA    ;;
 *)        DEVICE=TOUCH    ;;
esac

echo $NAME > $LOG
echo $MODEL_NUMBER >> $LOG
echo $DEVICE >> $LOG
echo $PLATFORM >> $LOG
echo $INTERFACE >> $LOG
echo $WIFI_MODULE >> $LOG

export DEVICE 
export PLATFORM 
export INTERFACE 
export WIFI_MODULE
export TMPDIR=/tmp/vlasovsoft
export LANG=en_US.UTF-8
export VLASOVSOFT_KEY=$ROOT/key
export VLASOVSOFT_KBD=$ROOT/kbd.txt
export VLASOVSOFT_FIFO1=$TMPDIR/fifo1
export VLASOVSOFT_FIFO2=$TMPDIR/fifo2
export VLASOVSOFT_I18N=$ROOT/i18n
export VLASOVSOFT_DICT=$ROOT/dictionary
export QT_PLUGIN_PATH=$ROOT/Qt/plugins
export LD_LIBRARY_PATH=$ROOT/Qt/lib

if [ $DEVICE == AURAH2O -o $DEVICE == GLOHD -o $DEVICE == TOUCH2 -o $DEVICE == AURAONE -o $DEVICE == AURA2 ]; then
    export QWS_MOUSE_PROTO=KoboTS_h2o
elif [ $DEVICE == AURAH2O2_v1 -o $DEVICE == AURAH2O2_v2 -o $DEVICE == CLARAHD -o $DEVICE == FORMA ]; then
    export QWS_MOUSE_PROTO=KoboTS_h2o2
else
    export QWS_MOUSE_PROTO=KoboTS
fi
echo $QWS_MOUSE_PROTO >> $LOG

export QWS_KEYBOARD=KoboKb
export QWS_DISPLAY=Transformed:KoboFB
export QT_QWS_FONTDIR=$ROOT/fonts
export STYLESHEET=$ROOT/eink.qss

. $ROOT/settings.sh

cd $ROOT

if [ -z "$VLASOVSOFT_KSM" ]; then
    # kill nickel
    killall nickel
    killall sickel
    killall hindenburg
    killall fmon
fi

$ROOT/upgrade_batch_old.sh

# make the temporary directory for Qt
mkdir -p $TMPDIR

# make fifos
mkfifo $VLASOVSOFT_FIFO1
mkfifo $VLASOVSOFT_FIFO2

# remount external SD card to read/write
/bin/mount -w -o remount /mnt/sd

# run launcher
if [ -z "$VLASOVSOFT_KSM" ]; then
    echo 0 > /sys/class/graphics/fb0/rotate
fi
$ROOT/launcher -qws -stylesheet $STYLESHEET > $LOG 2>&1

# remove fifos
rm $VLASOVSOFT_FIFO1
rm $VLASOVSOFT_FIFO2

$ROOT/upgrade_batch.sh

if [ -z "$VLASOVSOFT_KSM" ]; then
    if [ -f $ROOT/nickel ]; then
        # remount external SD card to read-only
        /bin/mount -r -o remount /mnt/sd
        . $ROOT/run_nickel.sh
    else
        /sbin/reboot
    fi
fi

