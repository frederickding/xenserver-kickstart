# CentOS 7.0 kickstart for XenServer
# branch: develop
##########################################

# Install, not upgrade
install

# Install from a friendly mirror and add updates
url --url http://mirror.rackspace.com/CentOS/7.0.1406/os/x86_64/
repo --name=centos-updates --mirrorlist=http://mirrorlist.centos.org/?release=7.0.1406&arch=x86_64&repo=updates

# Language and keyboard setup
lang en_US.UTF-8
keyboard us

# Configure networking without IPv6, firewall off

# for STATIC IP: uncomment and configure
# network --onboot=yes --device=eth0 --bootproto=static --ip=192.168.###.### --netmask=255.255.255.0 --gateway=192.168.###.### --nameserver=###.###.###.### --noipv6 --hostname=$$$

# for DHCP:
network --bootproto=dhcp --device=eth0 --onboot=on

firewall --enabled --ssh

# Set timezone
timezone --utc Etc/UTC

# Authentication
rootpw Asdfqwerty
# if you want to preset the root password in a public kickstart file, use SHA512crypt e.g.
# rootpw --iscrypted $6$9dC4m770Q1o$FCOvPxuqc1B22HM21M5WuUfhkiQntzMuAV7MY0qfVcvhwNQ2L86PcnDWfjDd12IFxWtRiTuvO/niB0Q3Xpf2I.
authconfig --enableshadow --passalgo=sha512

# SELinux enabled
selinux --enforcing

# Disable anything graphical
skipx
text
eula --agreed

# Setup the disk
zerombr
clearpart --all --drives=xvda
part /boot --fstype=ext3 --size=500 --asprimary
part / --fstype=ext4 --grow --size=1024 --asprimary
bootloader --timeout=5 --driveorder=xvda --append="console=hvc0"

# Shutdown when the kickstart is done
halt

# Minimal package set
%packages --excludedocs
@base
@network-file-system-client
deltarpm
yum-plugin-fastestmirror
-dracut-config-rescue
-fprintd-pam
-wireless-tools
-NetworkManager
%end

%post --erroronfail
#!/bin/sh
echo -n "Network fixes"
# initscripts don't like this file to be missing.
cat > /etc/sysconfig/network << EOF
NETWORKING=yes
NOZEROCONF=yes
EOF
echo .

# For cloud images, 'eth0' _is_ the predictable device name, since
# we don't want to be tied to specific virtual (!) hardware
rm -f /etc/udev/rules.d/70*
ln -s /dev/null /etc/udev/rules.d/80-net-name-slot.rules
echo .

# simple eth0 config, again not hard-coded to the build hardware
cat > /etc/sysconfig/network-scripts/ifcfg-eth0 << EOF
DEVICE="eth0"
BOOTPROTO="dhcp"
ONBOOT="yes"
TYPE="Ethernet"
PERSISTENT_DHCLIENT="yes"
EOF
echo .

# generic localhost names
cat > /etc/hosts << EOF
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6

EOF
echo .

# utility script
echo -n "Utility scripts"
wget -O /opt/domu-hostname.sh https://github.com/frederickding/xenserver-kickstart/raw/develop/opt/domu-hostname.sh
chmod +x /opt/domu-hostname.sh
echo .
%end