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

if [ -z "${offset}" ]; then
	echo "Invalid offset"
	exit 1
fi

mount -o loop,offset=$((offset * 512)) ${SELECT_IMAGE} mountpoint


##Execute command

#wifi
echo "wifi"
echo -n "WIFI SSID : "
read -r wifi_ssid
echo -n "WIFI PSK : "
read -r wifi_psk
if [ ! -e mountpointd/etc/wpa_supplicant ]; then
	mkdir -p mountpointd/etc/wpa_supplicant
fi
cat << EOF > mountpoint/etc/wpa_supplicant/wpa_supplicant.conf 
network={
	ssid="${wifi_ssid}"
	psk="${wifi_psk}"
}
EOF
echo

#locale
echo "Locale"
sed -i "s/# ko_KR.UTF-8/ko_KR.UTF-8/g" mountpint/etc/locale.gen
cmd "locale-gen"
echo

#timezone
echo "Timezone"
ln -sf /usr/share/zoneinfo/Asia/Seoul mountpoint/etc/localtime
echo

#skel
echo "skel"
cp -ar mountpoint/etc/skel/. mountpoint/root/
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
umount mountpoint
if mountpoint mountpoint ; then
	echo "Unmount failed"
else
	rm -rf mountpoint
fi

