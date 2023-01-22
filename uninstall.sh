#!/bin/bash
# uninstall minitowerkit script 
. /lib/lsb/init-functions

oled_svc="minitower_display_moodlight.service"
svclocation="/lib/systemd/system/${oled_svc}"

fan_pwm_svc="minitower_fan_pwm.service"
fan_pwm_svc_location="/lib/systemd/system/${fan_pwm_svc}"

log_action_msg "Uninstalling minitower moodlight Driver..."
sleep 1

log_action_msg "Remove dtoverlay configure from /boot/config.txt file"
sudo sed -i '/dtparam=i2c.*/ s/^/#/' /boot/config.txt

log_action_msg "Stop and disable ${oled_svc}"
sudo systemctl disable ${oled_svc} 2&>/dev/null  
sudo systemctl stop ${oled_svc}  2&>/dev/null

log_action_msg "Stop and disable ${fan_pwm_svc}"
sudo systemctl disable ${fan_pwm_svc} 2&>/dev/null  
sudo systemctl stop ${fan_pwm_svc}  2&>/dev/null

log_action_msg "Remove Minitower kit Driver..."
sudo rm -rf /lib/systemd/system/minitower_oled.service 2&>/dev/null
sudo rm -rf /lib/systemd/system/minitower_fan_pwm.service 2&>/dev/null

sudo rm -rf /usr/local/luma.examples/ 2&>/dev/null
sudo rm -rf /usr/local/rpi_ws281x/ 2&>/dev/null

log_success_msg "Uninstall Mini tower kit Driver Successfully." 
