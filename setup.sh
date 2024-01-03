#!/bin/bash
# This script will be downloaded and ran automatically

hostname=$(hostname)
if [[ "$hostname" != "screenmite" ]]; then
    echo "setting hostname to screenmite"
    hostnamectl set-hostname screenmite
else
    echo "The hostname is already set to screenmite"
fi

if [ ! -L "/usr/share/images/desktop-base/default_stock" ]; then
    mv /usr/share/images/desktop-base/default /usr/share/images/desktop-base/default_stock
else
    rm /usr/share/images/desktop-base/default    
fi
rm -rf /usr/share/images/wallpaper.png
mv $PWD/wallpaper.png /usr/share/images/wallpaper.png
ln -s /usr/share/images/wallpaper.png /usr/share/images/desktop-base/default




echo "Applying grub settings.."
rm -rf /boot/grub/theme
mv $PWD/grub_theme /boot/grub/theme
FILE='/etc/default/grub'
sed -i -e 's/GRUB_TIMEOUT=[0-9]\+/GRUB_TIMEOUT=5/g' $FILE
LINE='GRUB_THEME=/boot/grub/theme/theme.txt'
sed -i -e 's/GRUB_THEME=.*\+/GRUB_THEME=/boot/grub/theme/theme.txt/g' $FILE
grep -qF -- "$LINE" "$FILE" || echo "$LINE" >> "$FILE"
update-grub

echo "Installing unclutter (hides mouse cursor)"
sudo apt-get install unclutter -y
# unclutter will need a reboot for it to take effect



