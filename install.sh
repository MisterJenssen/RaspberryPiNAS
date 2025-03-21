#!/bin/bash

echo -n "Please enter username: "
read username

echo "User: $username"

. /lib/lsb/init-functions
sudo apt update && sudo apt -y -q install git cmake scons python3-dev || log_action_msg "please check internet connection and make sure it can access internet!" 

# install libraries. 
log_action_msg "Check dependencies and install deps packages..."
sudo apt -y install python3 python3-pip python3-pil python3-rpi.gpio python3-numpy python3-luma.oled python3-psutil libjpeg-dev zlib1g-dev libfreetype6-dev liblcms2-dev libopenjp2-7 libtiff6 && log_action_msg "deps packages installed successfully!" || log_warning_msg "deps packages install process failed, please check the internet connection..." 

# install psutil lib.
# sudo -H pip3 install psutil
# if [ $? -eq 0 ]; then
#	log_action_msg "psutil library has been installed successfully."
# fi

# grant privilledges to user pi.
sudo usermod -a -G gpio,i2c $username && log_action_msg "grant privilledges to user $username" || log_warning_msg "Grant privilledges failed!" 

# download driver from internet 
cd /usr/local/ 
if [ ! -d luma.examples ]; then
   cd /usr/local/
   git clone https://github.com/rm-hull/luma.examples.git && cd /usr/local/luma.examples/ && sudo cp -f /home/$username/absminitowerkit/sysinfo.py . || log_warning_msg "Could not download repository from github, please check the internet connection..." 
else
   # copy sysinfo.py application to /usr/local/luma.examples/examples/ folder.
   sudo cp -vf /home/$username/absminitowerkit/sysinfo.py /usr/local/luma.examples/examples/ 2>/dev/null
fi 

cd /usr/local/luma.examples/  && sudo -H pip3 install -e .  --break-system-packages && log_action_msg "Install dependencies packages successfully..." || log_warning_msg "Cound not access github repository, please check the internet connections!!!" 

# download rpi_ws281x libraries.
cd /usr/local/ 
if [ ! -d rpi_ws281x ]; then
   cd /usr/local/
   sudo git clone https://github.com/jgarff/rpi_ws281x && log_action_msg "Download moodlight driver finished..." || log_warning_msg "Could not access github repository, please check the internet connections!!!" 
   cd rpi_ws281x/ && sudo scons && mkdir build && cd build/ && cmake -D BUILD_SHARED=OFF -D BUILD_TEST=ON .. && sudo make install && log_action_msg "Installation finished..." || log_warning_msg "Installation process failed! Please try again..."
fi

# Enable i2c function on raspberry pi.
log_action_msg "Enable i2c on Raspberry Pi "

sudo sed -i '/dtparam=i2c_arm*/d' /boot/config.txt 
sudo sed -i '$a\dtparam=i2c_arm=on' /boot/config.txt 

if [ $? -eq 0 ]; then
   log_action_msg "i2c has been setting up successfully"
fi

# install minitower service.
log_action_msg "Minitower service installation begin..."

if [ -f /usr/bin/moodlight ]; then
   log_action_msg "moodlight driver install successfully"
fi

# file location folder.
file_location_folder="home/$username/RaspberryPiNAS"


# oled screen display & moodlight service.
oled_svc="minitower_display_moodlight"
oled_svc_file="/lib/systemd/system/${oled_svc}.service"
sudo rm -f ${oled_svc_file}

sudo echo "[Unit]" > ${oled_svc_file}
sudo echo "Description=Minitower Service" >> ${oled_svc_file}
sudo echo "DefaultDependencies=no" >> ${oled_svc_file}
sudo echo "StartLimitIntervalSec=60" >> ${oled_svc_file}
sudo echo "StartLimitBurst=5" >> ${oled_svc_file}
sudo echo "[Service]" >> ${oled_svc_file}
sudo echo "RootDirectory=/" >> ${oled_svc_file}
sudo echo "User=root" >> ${oled_svc_file}
sudo echo "Type=forking" >> ${oled_svc_file}
sudo echo "ExecStart=/bin/bash -c '/usr/bin/python3 ${file_location_folder}/sysinfo.py &'" >> ${oled_svc_file}
sudo echo "RemainAfterExit=yes" >> ${oled_svc_file}
sudo echo "Restart=always" >> ${oled_svc_file}
sudo echo "RestartSec=30" >> ${oled_svc_file}
sudo echo "[Install]" >> ${oled_svc_file}
sudo echo "WantedBy=multi-user.target" >> ${oled_svc_file}

log_action_msg "Minitower Service configuration ${oled_svc} finished." 
sudo chown root:root ${oled_svc_file}
sudo chmod 644 ${oled_svc_file}

log_action_msg "Minitower Service Load ${oled_svc} module." 
systemctl daemon-reload
systemctl enable ${oled_svc}.service
systemctl restart ${oled_svc}.service 


# fan PWM service.
fan_pwm_svc="minitower_fan_pwm"
fan_pwm_svc_file="/lib/systemd/system/${fan_pwm_svc}.service"
sudo rm -f ${fan_pwm_svc_file}

sudo echo "[Unit]" > ${fan_pwm_svc_file}
sudo echo "Description=Minitower fan PWM Service" >> ${fan_pwm_svc_file}
sudo echo "DefaultDependencies=no" >> ${fan_pwm_svc_file}
sudo echo "StartLimitIntervalSec=60" >> ${fan_pwm_svc_file}
sudo echo "StartLimitBurst=5" >> ${fan_pwm_svc_file}
sudo echo "[Service]" >> ${fan_pwm_svc_file}
sudo echo "RootDirectory=/" >> ${fan_pwm_svc_file}
sudo echo "User=root" >> ${fan_pwm_svc_file}
sudo echo "Type=forking" >> ${fan_pwm_svc_file}
sudo echo "ExecStart=/bin/bash -c '/usr/bin/python3 ${file_location_folder}/fan_pwm.py &'" >> ${fan_pwm_svc_file}
sudo echo "RemainAfterExit=yes" >> ${fan_pwm_svc_file}
sudo echo "Restart=always" >> ${fan_pwm_svc_file}
sudo echo "RestartSec=30" >> ${fan_pwm_svc_file}
sudo echo "[Install]" >> ${fan_pwm_svc_file}
sudo echo "WantedBy=multi-user.target" >> ${fan_pwm_svc_file}

log_action_msg "Minitower Service configuration ${fan_pwm_svc} finished." 
sudo chown root:root ${fan_pwm_svc_file}
sudo chmod 644 ${fan_pwm_svc_file}

log_action_msg "Minitower Service Load ${fan_pwm_svc} module." 
systemctl daemon-reload
systemctl enable ${fan_pwm_svc}.service
systemctl restart ${fan_pwm_svc}.service 

# Finished 
log_success_msg "Minitower service installation finished successfully." 

# greetings and require rebooting system to take effect.
log_action_msg "Please reboot Raspberry Pi and Have fun!" 
sudo sync
