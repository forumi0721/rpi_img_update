#!/usr/bin/env bash

##EUID Check
if [ "${EUID}" != "0" ]; then
	sudo ${0} ${@}
	exit $?
fi


##CHROOT Function
cmd() {
	PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin" LC_ALL=C LANG=C TERM=xterm chroot mountpoint /bin/bash -c "${1}"
}


##Image Select
SELECT_IMAGE=

img_list=()
index=1
for img in $(ls *.img)
do
	echo "${index} : ${img}"
	img_list+=(${img})
	index=$((index + 1))
done

if [ "${index}" == "1" ]; then
	echo "Cannot found image"
	exit 1
fi

echo ""
echo -n "Select Image : "
read -r img_no

if [[ ${img_no} != *[[:digit:]]* ]] || [ "${#img_list[@]}" -lt "${img_no}" -o "${img_no}" -le 0 ] 2> /dev/null; then
	echo "Invalid image no"
	exit 1
fi

SELECT_IMAGE=${img_list[$((img_no - 1))]}


##Mount Image
if [ -e mountpoint ]; then
	if mountpoint mountpoint ; then
		umount mountpoint
		if mountpoint mountpoint ; then
			echo "Mount point cannot unmount"
			exit 1
		fi
	fi
	rm -rf mountpoint
fi

mkdir -p mountpoint

offset=$(fdisk ${SELECT_IMAGE} -l | grep Linux$ | sed 's/\s\+/ /g' | cut -f 2 -d ' ')
offset_boot=$(fdisk ${SELECT_IMAGE} -l | grep "W95 FAT32" | sed 's/\s\+/ /g' | cut -f 2 -d ' ')

if [ -z "${offset}" ]; then
	echo "Invalid offset"
	exit 1
fi

mount -o loop,offset=$((offset * 512)) ${SELECT_IMAGE} mountpoint
if [ ! -z "${offset_boot}" ]; then
	mount -o loop,offset=$((offset_boot * 512)) ${SELECT_IMAGE} mountpoint/boot
fi


##Execute command

#hostname
echo "hostname"
echo -n "HOSTNAME : "
read -r hostname
if [ ! -z "${hostname}" ]; then
	echo "${hostname}" > mountpoint/etc/hostname
fi
echo

#passwd
echo "password"
echo -n "ROOT PASSWORD : "
read -r root_passwd
if [ ! -z "${root_passwd}" ]; then
	echo ${root_passwd} | passwd root --stdin
fi
echo -n "PI PASSWORD : "
read -r pi_passwd
if [ ! -z "${pi_passwd}" ]; then
	echo ${pi_passwd} | passwd root --stdin
fi
echo

#wifi
echo "wifi"
echo -n "WIFI SSID : "
read -r wifi_ssid
echo -n "WIFI PSK : "
read -r wifi_psk
echo -n "WIFI Country : "
read -r wifi_country
if [ ! -e mountpoint/etc/wpa_supplicant ]; then
	mkdir -p mountpoint/etc/wpa_supplicant
fi
cat << EOF > mountpoint/etc/wpa_supplicant/wpa_supplicant.conf 
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
update_config=1
country=${wifi_country}

network={
	ssid="${wifi_ssid}"
	psk="${wifi_psk}"
	key_mgmt=WPA-PSK
}
EOF
echo

#locale
echo "Locale"
sed -i "s/^en_GB.UTF-8/# en_GB.UTF-8/g" mountpoint/etc/locale.gen
sed -i "s/^# ko_KR.UTF-8/ko_KR.UTF-8/g" mountpoint/etc/locale.gen
cmd "locale-gen"
#cmd "update-locale LANG=ko_KR.UTF-8"
cat << 'EOF' > mountpoint/etc/default/locale
if [ -z "${TERM}" -o "${TERM}" = "linux" -o "${TERM}" = "vt220" -o "${TERM}" = "dumb" ]; then
        LANG=C
else
        LANG=ko_KR.UTF-8
fi
EOF
echo

#timezone
echo "Timezone"
ln -sf /usr/share/zoneinfo/Asia/Seoul mountpoint/etc/localtime
echo

#keyboard
echo "Keyboard"
cat << EOF > mountpoint/etc/default/keyboard
# KEYBOARD CONFIGURATION FILE

# Consult the keyboard(5) manual page.

XKBMODEL="pc105"
XKBLAYOUT="kr"
XKBVARIANT="kr104"
XKBOPTIONS=""

BACKSPACE="guess"
EOF
echo

#skel
echo "skel"
cp -ar mountpoint/etc/skel/. mountpoint/root/
echo

#Firmware
echo "Firmware"
cmd "apt-get install ca-certificates git-core -y && wget http://goo.gl/1BOfJ -O /usr/bin/rpi-update && chmod +x /usr/bin/rpi-update && rpi-update"
echo

#update
echo "Update"
cmd "apt-get update -o Acquire::CompressionTypes::Order::=gz"
cmd "apt-get dist-upgrade -y"
cmd "apt-get autoremove --purge -y"
cmd "apt-get autoclean -y"
cmd "apt-get clean"
cmd "find /var/lib/apt -type f -exec rm \"{}\" \\;"
echo


##Unmount Image
if mountpoint mountpoint/boot ; then
	umount mountpoint/boot
fi
umount mountpoint
if mountpoint mountpoint ; then
	echo "Unmount failed"
else
	rm -rf mountpoint
fi

