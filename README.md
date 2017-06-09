# PX4 Installation on Snapdragon #
This package provides a modified version of the PX4 source code for the Snapdragon platform.
For the moment it is only applicable for Snapdragon with official ESC but updates on the process with off the shell ESC are coming.

This package is to be compiled on a linux machine and will then be pushed on the snapdragon via adb or ssh.

## Prerequisites ##
Some basics dependencies have to be install on your LINUX host system.
```sh
sudo usermod -a -G dialout $USER
sudo add-apt-repository ppa:george-edison55/cmake-3.x -y
sudo apt-get update
sudo apt-get install python-argparse git-core wget zip \
    python-empy qtcreator cmake build-essential genromfs -y
# simulation tools
sudo apt-get install ant protobuf-compiler libeigen3-dev libopencv-dev openjdk-8-jdk openjdk-8-jre clang-3.5 lldb-3.5 -y
# required python packages
sudo apt-get install python-pip
sudo -H pip install pandas jinja2
sudo apt-get install android-tools-adb android-tools-fastboot fakechroot fakeroot unzip xz-utils wget python python-empy -y
```
## Cross_toolchain installation ##
These instuctions describe the default installation proceedure for the Hexagon SDK and Tools. The packages will be installed to ~/Qualcomm. The top working dir is assumed to be the user home directory (~), and downloads are assumed to be in ~/Downloads for simplicity.

First, Download these files:

+++[Hexagon SDK 3.0 for Linux](https://developer.qualcomm.com/software/hexagon-dsp-sdk/tools).You will have to use a browser as it requires QDN registration and a click through.

+++[Flight_3.1.3_qrlSDK , Flight_X.X.X_JFlash , qcom_flight_controller_hexagon_sdk_add_on] (https://support.intrinsyc.com). You will need a login that you will be asked to request on the intrynsic website and which is based on the unique ID of your snapdragon board.

### Installing the cross compiler toolchain ###
Clone the following:
```sh
git clone https://github.com/ATLFlight/cross_toolchain
```
Copy Hexagon SDK 3.0 for Linux, qrlSDK  to the downloads dir of cross_toolchain cloned
```sh
cp ~/Downloads/{name of file downloaded, eg. qualcomm_hexagon_sdk_lnx_3_0_eval.bin, Flight_3.1.3_qrlSDK} cross_toolchain/downloads
```
Now run the install script
```sh
cd cross_toolchain
./installsdk.sh --APQ8074 --arm-gcc --qrlSDK
```
The script will prompt you to optionally update the default installation path ${HEXAGON_INSTALL_HOME} and uses the following environment variables for the installation. Assuming you select the default install path of ${HOME} the environment settings would be:
```sh
echo "export HEXAGON_INSTALL_HOME=${HOME}" >> ~/.bashrc
echo "export HEXAGON_SDK_ROOT=${HEXAGON_INSTALL_HOME}/Qualcomm/Hexagon_SDK/3.0" >> ~/.bashrc
echo "export HEXAGON_TOOLS_ROOT=${HEXAGON_INSTALL_HOME}/Qualcomm/HEXAGON_Tools/7.2.12/Tools" >> ~/.bashrc
echo "export HEXAGON_ARM_SYSROOT=${HEXAGON_INSTALL_HOME}/Qualcomm/qrlinux_v4_sysroot/merged-rootfs" >> ~/.bashrc
echo "export ARM_CROSS_GCC_ROOT=${HEXAGON_INSTALL_HOME}/Qualcomm/ARM_Tools/gcc-4.9-2014.11" >> ~/.bashrc
source ~/.bashrc
```
Make sure these variables are set when building code using the Hexagon SDK and Hexagon Tools.

### Flashing the Snapdragon and Update ADSP Firmware (Done once unless flashing is needed) ###
#### Flashing procedure ####
Flashing the Linux image will erase everything on the Snapdragon. Back up your work before you perform this step!
Make sure the board can be found using adb:
```sh
adb devices
```
Then, reboot it into the fastboot bootloader:
```sh
adb reboot bootloader
```
Unzip the Flight_X.X.X_JFlash.zip  downloaded from Intrynsic. For instance :
```sh
cd ~/Downloads
unzip Flight_3.1.2_JFlash.zip
cd flight_3.1.2
./jflash.sh
```
#### Update ADSP Firmware ####
Load this file locally :
```sh
adb pull /usr/local/qr-linux/q6-admin.sh
```
Edit it :
```sh
gedit q6-admin.sh
```
Comment out the while loopS causing boot to hang:
```sh
# Wait for adsp.mdt to show up
#while [ ! -s /lib/firmware/adsp.mdt ]; do
#  sleep 0.1
#done
```
and
```sh
# Don't leave until ADSP is up
#while [ "`cat /sys/kernel/debug/msm_subsys/adsp`" != "2" ]; do
#  sleep 0.1
#done
```
Finally push back the modyfied file :
```sh
adb push q6-admin.sh /usr/local/qr-linux/q6-admin.sh
```
##### And make sure to execute this : #####
```sh
adb shell chmod +x /usr/local/qr-linux/q6-admin.sh
```

Now just push the latest ADSP firmware files. You will need to uncompress qcom_flight_controller_hexagon_sdk_add_on
which you downloaded earlie.
```sh
cd ~/Downloads
mkdir hexagon_add_on && cd hexagon_add_on
unzip ../qcom_flight_controller_hexagon_sdk_add_on.zip
./installfcaddon.sh
```
Finally 
```sh
adb reboot
```

You can find instructions for setting WIFI [HERE](https://dev.px4.io/en/flight_controller/snapdragon_flight_advanced.html#wifi-settings).
For more details and Troubleshooting, Look [HERE](https://dev.px4.io/en/flight_controller/snapdragon_flight_advanced.html)
and [HERE] (https://github.com/ATLFlight).

## Building PX4 Software
```sh
mkdir -p ~/src
cd ~/src
git clone https://github.com/u-t-autonomous/PX4_Snapdragon.git
cd PX4_Snapdragon
git submodule update --init --recursive
make eagle_legacy_default
make eagle_legacy_default upload
adb push ROMFS/px4fmu_common/mixers/quad_x.main.mix  /usr/share/data/adsp
adb push config_files/px4.config /usr/share/data/adsp
```

## Running PX4 over ssh ##
This supposed that the wifi have been configured !
Supposing that the quad IP is 192.168.1.X (ifconfig in adb shell)
```sh
ssh linaro@192.168.1.X
```
password = linaro
```sh
sudo ./px4 mainapp.config
```
Now look at this repositories for [OFFBOARD control](https://github.com/u-t-autonomous/PX4_ROS_packages).

## Gazebo simulation ###

## Project Milestones

The PX4 software and Pixhawk hardware (which has been designed for it) has been created in 2011 by [Lorenz Meier](https://github.com/LorenzMeier).
