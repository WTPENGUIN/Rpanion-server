#!/bin/bash

set -e
set -x

git submodule update --init --recursive

echo "export PATH=$PATH:$HOME/.local/bin" >> ~/.bashrc

## Need to temp disable this
sudo systemctl stop unattended-upgrades.service

## Remove this to disable the "Pending Kernel Upgrade" message
# sudo apt -y remove needrestart

## Packages
sudo apt update
sudo apt upgrade -y
sudo apt install -y libgstreamer1.0-dev libgstrtspserver-1.0-dev gstreamer1.0-plugins-good gstreamer1.0-plugins-base-apps network-manager python3 python3-dev python3-gst-1.0 python3-pip dnsmasq git ninja-build wireless-tools gstreamer1.0-plugins-ugly

sudo apt purge -y modemmanager

sudo systemctl disable dnsmasq

curl -sL https://deb.nodesource.com/setup_16.x | sudo -E bash -
sudo apt install -y nodejs

sudo pip3 install meson
pip3 install netifaces --user

## Configure nmcli to not need sudo
sudo sed -i.bak -e '/^\[main\]/aauth-polkit=false' /etc/NetworkManager/NetworkManager.conf

## Ensure nmcli can manage all network devices
sudo touch /etc/NetworkManager/conf.d/10-globally-managed-devices.conf
echo "[keyfile]" | sudo tee -a /etc/NetworkManager/conf.d/10-globally-managed-devices.conf >/dev/null
echo "unmanaged-devices=*,except:type:wifi,except:type:gsm,except:type:cdma,except:type:wwan,except:type:ethernet,type:vlan" | sudo tee -a /etc/NetworkManager/conf.d/10-globally-managed-devices.conf >/dev/null
sudo service network-manager restart

## Zerotier and wireguard
curl -s https://install.zerotier.com | sudo bash
sudo apt install -y wireguard wireguard-tools resolvconf

## mavlink-router
./build_mavlinkrouter.sh

## and build & run Rpanion
./build.sh

## Pymavlink and gpsbabel to create KMZ.
sudo apt install -y libxml2-dev libxslt1-dev
DISABLE_MAVNATIVE=True python3 -m pip install --upgrade pymavlink --user
sudo apt-get install -y gpsbabel zip

## And re-enable
sudo systemctl start unattended-upgrades.service

sudo reboot