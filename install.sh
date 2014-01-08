#!/bin/bash

source settings.sh

PWD=`pwd`

#Check if we're running as root
if [ "$(id -u)" != "0" ]; then
  echo "\e[1;31mYou need to run this script as root!\e[0m"
  exit;
fi

###FUNCTIONS###

function message()
{
  echo -e "\e[1;32m"
  echo $1
  echo -e "\e[0m"
}


##SYSTEM##

message "Changing login credentials for root and xbian"
xbian-config rootpass update $ROOT_PASS
xbian-config xbianpass update $XBIAN_PASS

message "Changing hostname to '$HOSTNAME'"
xbian-config hostname update $HOSTNAME

message "Setting timezone to EU/Amsterdam"
xbian-config timezone update europe amsterdam

message "Configuring video settings"
xbian-config videoflags update hdmi_force_hotplug disable_overscan disable_splash

if [ "$CONFIGURE_WIFI" -eq 1 ]
then
        message “Configuring wifi connectivity”
        cp $PWD/etc/network/interfaces /etc/network/interfaces
        cp $PWD/wpa_supplicant.conf /etc/wpa_supplicant/wpa_supplicant.conf
else
        message "Skipping wifi configuration"
fi

if [ -n "$EXTERNAL_HDD_SYM_NAME" ]
then
	message "Creating external HDD symlink folder"
	ln -s /media/usb0/ /$EXTERNAL_HDD_SYM_NAME
else
	message "Skipping external HDD symlink creation"
fi

message "Copying over usbmount configuration file"
cp $PWD/etc/usbmount/usbmount.conf /etc/usbmount/usbmount.conf

##SAMBA##

message "Installing ntfs-3g and samba"
apt-get -qq install ntfs-3g samba samba-common-bin

message "Creating SMB usergroup samba"
groupadd samba

message "Creating SMB user $SAMBA_USER"
useradd -M -G samba $SAMBA_USER
echo -e "$SAMBA_PASS\n$SAMBA_PASS" | (passwd $SAMBA_USER)
echo -e "$SAMBA_PASS\n$SAMBA_PASS" | (smbpasswd -a -s $SAMBA_USER)

message "Copying over samba configuration file"
cp $PWD/smb.conf /etc/samba/smb.conf

message "Restarting samba"
service samba restart

##XBMC##
message "Copying over XBMC configuration file"
cp $PWD/home/xbian/.xbmc/userdata/advancedsettings.xml /home/xbian/.xbmc/userdata/advancedsettings.xml

if [ "$INSTALL_SOURCES_LIST" -eq 1 ]
then
	message "Copying over XBMC sources file"
	cp $PWD/home/xbian/.xbmc/userdata/sources.xml /home/xbian/.xbmc/userdata/sources.xml
else
	message "Skipping XBMC sources list"
fi

if [ "$INSTALL_UPC_REMOTE" -eq 1 ]
then
	message "Installing UPC Remote keymap"
	cp $PWD/etc/lirc/remotes/upc_remote.conf /etc/lirc/remotes/upc_remote.conf
	echo "include \"/etc/lirc/remotes/upc_remote.conf\"" >> /etc/lirc/lircd.conf
	cp $PWD/home/xbian/.xbmc/userdata/Lircmap.xml /home/xbian/.xbmc/userdata/Lircmap.xml
else
	message "Skipping UPC Remote installation"
fi

##AirPlay##
message "Hotfixing AirPlay functionality"
echo "frandom" >> /etc/modules

##CLEANUP##
message "[You're probably going to want to reboot right around now.]"
