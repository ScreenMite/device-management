#!/bin/bash

echo "stopping lightdm"
systemctl stop lightdm
echo "configuring lightdm"
# xfce auto-login
cat <<EOF >> /etc/lightdm/lightdm.conf
[SeatDefaults]
autologin-user=miteadmin
autologin-user-timeout=0
autologin-session=xfce
EOF
echo "Configuring xfce4 settings for \"miteadmin\""
sudo -u miteadmin bash -c 'mkdir -p /home/miteadmin/.config/xfce4/xfconf/xfce-perchannel-xml'
sudo -u miteadmin bash -c 'rm /home/miteadmin/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-power-manager.xml'
sudo -u miteadmin bash -c 'cat <<EOF >> /home/miteadmin/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-power-manager.xml
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfce4-power-manager" version="1.0">
  <property name="xfce4-power-manager" type="empty">
    <property name="power-button-action" type="uint" value="4"/>
    <property name="show-tray-icon" type="bool" value="false"/>
    <property name="dpms-enabled" type="bool" value="true"/>
    <property name="dpms-on-ac-sleep" type="uint" value="0"/>
    <property name="blank-on-ac" type="int" value="0"/>
    <property name="dpms-on-ac-off" type="uint" value="0"/>
    <property name="dpms-on-battery-sleep" type="uint" value="0"/>
    <property name="blank-on-battery" type="int" value="0"/>
    <property name="dpms-on-battery-off" type="uint" value="0"/>
    <property name="inactivity-on-battery" type="uint" value="14"/>
    <property name="lock-screen-suspend-hibernate" type="bool" value="false"/>
    <property name="logind-handle-lid-switch" type="bool" value="false"/>
  </property>
</channel>
EOF'
sudo -u miteadmin bash -c 'rm /home/miteadmin/.config/xfce4/xfconf/xfce-perchannel-xml/displays.xml'
sudo -u miteadmin bash -c 'cat <<EOF >> /home/miteadmin/.config/xfce4/xfconf/xfce-perchannel-xml/displays.xml
<?xml version="1.0" encoding="UTF-8"?>
<channel name="displays" version="1.0">
  <property name="Notify" type="int" value="3"/>
</channel>
EOF'
sudo -u miteadmin bash -c 'rm /home/miteadmin/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml'
sudo -u miteadmin bash -c 'cat <<EOF >> /home/miteadmin/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfce4-panel" version="1.0">
  <property name="configver" type="int" value="2"/>
  <property name="panels" type="array">
    <value type="int" value="1"/>
    <property name="dark-mode" type="bool" value="true"/>
    <property name="panel-1" type="empty">
      <property name="position" type="string" value="p=6;x=0;y=0"/>
      <property name="length" type="uint" value="100"/>
      <property name="position-locked" type="bool" value="true"/>
      <property name="icon-size" type="uint" value="0"/>
      <property name="size" type="uint" value="26"/>
      <property name="plugin-ids" type="array">
        <value type="int" value="2"/>
        <value type="int" value="1"/>
        <value type="int" value="10"/>
      </property>
      <property name="enter-opacity" type="uint" value="100"/>
      <property name="leave-opacity" type="uint" value="0"/>
      <property name="background-style" type="uint" value="0"/>
      <property name="autohide-behavior" type="uint" value="2"/>
    </property>
  </property>
  <property name="plugins" type="empty">
    <property name="plugin-10" type="string" value="notification-plugin"/>
    <property name="plugin-1" type="string" value="separator">
      <property name="expand" type="bool" value="true"/>
      <property name="style" type="uint" value="0"/>
    </property>
    <property name="plugin-2" type="string" value="applicationsmenu"/>
  </property>
</channel>
EOF'
sudo -u miteadmin bash -c 'rm /home/miteadmin/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-desktop.xml'
sudo -u miteadmin bash -c 'cat <<EOF >> /home/miteadmin/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-desktop.xml
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfce4-desktop" version="1.0">
  <property name="desktop-icons" type="empty">
    <property name="style" type="int" value="0"/>
  </property>
</channel>
EOF'
echo "restarting lightdm"
systemctl restart lightdm


# Define the path to the scripts
SCRIPT_PATH="/usr/local/bin"
# Define the name of the service
SERVICE_NAME="screenmite_updater"
# Define the GitHub repository
GITHUB_REPO="ScreenMite/device-management"
# Create the directory for the scripts if it doesn't exist
mkdir -p $SCRIPT_PATH
# Create the service script
cat > $SCRIPT_PATH/$SERVICE_NAME.sh << EOF
#!/bin/bash
# This script will be run by the service
pstatus () {
    echo "\$1" >> /var/log/$SERVICE_NAME.log
    echo "\$1"
}

dlfolder="downloaded"
# mode="SOURCE"
mode="RELEASE"

while true; do
    pstatus "Running service updater"

    pstatus "Waiting for internet connection..."
    while true; do
        if ping -c 3 1.1 > /dev/null 2>&1; then
            pstatus "Internet is online"
            break
        else
            sleep 5
       fi
    done

    apt-get update && apt upgrade -y
    apt-get install unattended-upgrades jq git curl -y

    rm -rf "\$dlfolder"

    # Download the latest release from the GitHub repository
    if [[ \$mode == "RELEASE" ]]; then
        pstatus "Downloading the latest release from the GitHub repository..."
        LATEST_RELEASE=\$(curl --silent "https://api.github.com/repos/$GITHUB_REPO/releases/latest" | jq -r .tag_name)
        SCRIPT_VER="none"
        if [[ -f version.txt ]]; then
            read SCRIPT_VER < version.txt
        fi
        if [[ \$LATEST_RELEASE != "" && \$LATEST_RELEASE != "null" && \$LATEST_RELEASE != \$SCRIPT_VER ]]; then
            echo "String is not null"
            wget https://github.com/$GITHUB_REPO/archive/\$LATEST_RELEASE.tar.gz
            # Extract the release
            tar xzf \$LATEST_RELEASE.tar.gz -C "\$dlfolder" .
            echo \$SCRIPT_VER > version.txt
        else
            pstatus "Version from GitHub was \$LATEST_RELEASE (invalid or same as current)"
        fi
    fi
    if [[ \$mode == "SOURCE" || \$LATEST_RELEASE == "null" ]]; then
        pstatus "Downloading from source, rather than release"
        git clone --depth 1 "https://github.com/$GITHUB_REPO" "\$dlfolder"
    fi

    if [[ -f "./\$dlfolder/setup.sh" ]]; then
        pstatus "Running downloaded setup.sh"
        # Execute the extracted script
        chmod +x "./\$dlfolder/setup.sh"
        bash -c "cd \$dlfolder ; ./setup.sh"
        pstatus "Updater success. Trying again in 23-25 hours..."
        sleep \$(( RANDOM % 2 + 23 ))h
    else
        pstatus "Updater failed. Trying again in 5-10 minutes..."
        sleep \$(( RANDOM % 5 + 5 ))m
    fi
done

EOF

# Make the service script executable
chmod +x $SCRIPT_PATH/$SERVICE_NAME.sh
# Create the service file
cat > /etc/systemd/system/$SERVICE_NAME.service << EOF
[Unit]
Description=$SERVICE_NAME
After=network.target

[Service]
ExecStart=$SCRIPT_PATH/$SERVICE_NAME.sh
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
# Enable the service
systemctl enable $SERVICE_NAME
systemctl restart $SERVICE_NAME
