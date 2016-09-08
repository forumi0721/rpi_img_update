#!/usr/bin/env bash

###EUID Check
#if [ "${EUID}" != "0" ]; then
#	sudo ${0} ${@}
#	exit $?
#fi


##Image Select
echo "1 : Raspbian (Full Version)"
echo "2 : Raspbian (Lite Version)"
echo "3 : Retro Pie"
echo ""
echo -n "Select Image : "
read -r img_no

if [ "${img_no}" == "1" ]; then
	wget https://downloads.raspberrypi.org/raspbian_latest -O rpi_full.zip
	unzip rpi_full.zip
elif [ "${img_no}" == "2" ]; then
	wget https://downloads.raspberrypi.org/raspbian_lite_latest -O rpi_lite.zip
	unzip rpi_lite.zip
elif [ "${img_no}" == "3" ]; then
	wget https://github.com/RetroPie/RetroPie-Setup/releases/download/4.0.2/retropie-4.0.2-rpi2_rpi3.img.gz -O retro.img.gz
	gunzip retro.img.gz
else
	echo "Invalid image no"
	exit 1
fi

