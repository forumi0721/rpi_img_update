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
echo "4 : Raspbian (Full Version) Unpack"
echo "5 : Raspbian (Lite Version) Unpack"
echo "6 : Retro Pie Unpack"
echo ""
echo -n "Select Image : "
read -r img_no

if [ "${img_no}" == "1" ]; then
	wget https://downloads.raspberrypi.org/raspbian_latest -O rpi_full.zip
	unzip -o rpi_full.zip
elif [ "${img_no}" == "2" ]; then
	wget https://downloads.raspberrypi.org/raspbian_lite_latest -O rpi_lite.zip
	unzip -o rpi_lite.zip
elif [ "${img_no}" == "3" ]; then
	wget https://github.com/RetroPie/RetroPie-Setup/releases/download/4.0.2/retropie-4.0.2-rpi2_rpi3.img.gz -O retro.img.gz
	gunzip -f -k retro.img.gz
elif [ "${img_no}" == "4" ]; then
	if [ ! -e rpi_full.zip ]; then
		echo "Download First"
		exit 1
	else
		unzip -o rpi_full.zip
	fi
elif [ "${img_no}" == "5" ]; then
	if [ ! -e rpi_lite.zip ]; then
		echo "Download First"
		exit 1
	else
		unzip -o rpi_lite.zip
	fi
elif [ "${img_no}" == "6" ]; then
	if [ ! -e retro.img.gz ]; then
		echo "Download First"
		exit 1
	else
		gunzip -f -k retro.img.gz
	fi
else
	echo "Invalid image no"
	exit 1
fi

