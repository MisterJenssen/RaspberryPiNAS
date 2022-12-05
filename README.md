# NAS kit
Hardware: https://wiki.52pi.com/index.php?title=ZP-0130-4wire
Source: https://github.com/geeekpi/absminitowerkit

## Install NAS kit hardware
* 1. Download the latest image from https://www.raspberrypi.com/software/
* 2. Flash it to your TF Card with etcher tool, Download link: https://etcher.io/
* 3. After flashing, insert the TF card back to Raspberry Pi card Slot.
* 4. Power up your Raspberry Pi and make sure it can access internet.
* 5. Update Repository and Upgrade packages.
```bash
sudo apt update 
sudo apt upgrade -y 
```
* 6. Enable I2C on Raspberry Pi.
```bash
sudo raspi-config
```
Navigate to `Interface Options` -> `I2C` -> Enable -> Select `YES`. 

* 7. Make PWM work

Since this library and the onboard Raspberry Pi audio both use the PWM, they cannot be used together. You will need to blacklist the Broadcom audio kernel module by creating a blacklist file and adding the audio kernel module to it.
```bash
touch /etc/modprobe.d/snd-blacklist.conf
echo "blacklist snd_bcm2835" >> ./etc/modprobe.d/snd-blacklist.conf
```

* 8. Clone Repository.
```bash
git clone https://github.com/MisterJenssen/RaspberryPiNAS.git
```
* 9. Install driver.
```bash
cd RaspberryPiNAS/
sudo ./install.sh
```
* 10. Reboot and have fun.
```bash
sudo sync
sudo reboot
```

# Create a RAID setup (optional)
https://www.makeuseof.com/how-to-set-up-raid-1-on-the-raspberry-pi/

# Create and access NAS
https://www.seeedstudio.com/blog/2019/12/24/how-to-build-a-raspberry-pi-4-nas-server-samba-and-omv/

NOTE: OMV will only work on the headless version of Raspbian OS

NOTE: When adding a user to control your NAS, make sure it has also the necessary r/w/x access to the NAS folder
