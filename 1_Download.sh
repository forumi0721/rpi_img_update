#!/usr/bin/env bash

###EUID Check
#if [ "${EUID}" != "0" ]; then
#	sudo ${0} ${@}
#	exit $?
#fi


##Image Select
echo "1 : Full Version"
echo "2 : Lite Version"
echo ""
echo -n "Select Image : "
read -r img_no

if [ "${img_no}" == "1" ]; then
	wget https://downloads.raspberrypi.org/raspbian_latest -O rpi_full.zip
	unzip rpi_full.zip
elif [ "${img_no}" == "2" ]; then
	wget https://downloads.raspberrypi.org/raspbian_lite_latest -O rpi_lite.zip
	unzip rpi_lite.zip
else
	echo "Invalid image no"
	exit 1
fi

