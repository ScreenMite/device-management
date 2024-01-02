hostname=$(hostname)
if [[ "$hostname" != "screenmite" ]]; then
    echo "setting hostname to screenmite"
    hostnamectl set-hostname screenmite
else
    echo "The hostname is already set to screenmite"
fi

echo "Applying grub settings.."
rm -rf /boot/grub/theme
mv $PWD/grub_theme /boot/grub/theme
FILE='/etc/default/grub'
sed -i -e 's/GRUB_TIMEOUT=[0-9]\+/GRUB_TIMEOUT=1/g' $FILE
LINE='GRUB_THEME=/boot/grub/theme/theme.txt'
sed -i -e 's/GRUB_THEME=.*\+/GRUB_THEME=/boot/grub/theme/theme.txt/g' $FILE
grep -qF -- "$LINE" "$FILE" || echo "$LINE" >> "$FILE"
update-grub