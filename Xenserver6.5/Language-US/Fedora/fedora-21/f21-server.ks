# Fedora 21 Server kickstart for XenServer
# branch: develop
##########################################

# Install, not upgrade
install

# Install from a friendly mirror and add updates
url --mirrorlist=http://mirrors.fedoraproject.org/mirrorlist?repo=fedora-install-21&arch=$basearch
# repo --name=fedora --mirrorlist=http://mirrors.fedoraproject.org/mirrorlist?repo=fedora-$releasever&arch=$basearch
repo --name=updates --mirrorlist=http://mirrors.fedoraproject.org/mirrorlist?repo=updates-released-f$releasever&arch=$basearch

# Language and keyboard setup
lang en_US.UTF-8
keyboard us

# Configure networking without IPv6, firewall off

# for STATIC IP: uncomment and configure
# network --onboot=yes --device=eth0 --bootproto=static --ip=192.168.###.### --netmask=255.255.255.0 --gateway=192.168.###.### --nameserver=###.###.###.### --noipv6 --hostname=$$$

# for DHCP:
network --bootproto=dhcp --device=eth0 --onboot=on

firewall --disabled

# Set timezone
timezone --utc Etc/UTC

# Authentication
rootpw --lock --iscrypted locked
user --name=fedora --password=Asdfqwerty --plaintext --gecos="Fedora User" --shell=/bin/bash --groups=user,wheel
# if you want to preset the root password in a public kickstart file, use SHA512crypt e.g.
# rootpw --iscrypted $6$9dC4m770Q1o$FCOvPxuqc1B22HM21M5WuUfhkiQntzMuAV7MY0qfVcvhwNQ2L86PcnDWfjDd12IFxWtRiTuvO/niB0Q3Xpf2I.
authconfig --enableshadow --passalgo=sha512

# SELinux enabled
selinux --enforcing

# Disable anything graphical
skipx
text

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

# as of Fedora 21, we build a Fedora Server-like image rather than a 
# Fedora Cloud image, since newer guests should be PVHVM rather than PV
@^server-product-environment

yum-plugin-fastestmirror
dracut-config-generic
-dracut-config-rescue
-plymouth
-fprintd-pam
-wireless-tools
-iprutils
%end

# Copy grub.cfg to a backup and then make adaptations for buggy pygrub
%post --log=/root/ks-post.log

echo -n "Network fixes"
# initscripts don't like this file to be missing.
cat > /etc/sysconfig/network << EOF
NETWORKING=yes
NOZEROCONF=yes
EOF
echo -n "."

# For cloud images, 'eth0' _is_ the predictable device name, since
# we don't want to be tied to specific virtual (!) hardware
rm -f /etc/udev/rules.d/70*
ln -s /dev/null /etc/udev/rules.d/80-net-name-slot.rules
echo -n "."

# simple eth0 config, again not hard-coded to the build hardware
cat > /etc/sysconfig/network-scripts/ifcfg-eth0 << EOF
DEVICE="eth0"
BOOTPROTO="dhcp"
ONBOOT="yes"
TYPE="Ethernet"
PERSISTENT_DHCLIENT="yes"
EOF
echo -n "."

# generic localhost names
cat > /etc/hosts << EOF
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6

EOF
echo -n "."

# Because memory is scarce resource in most cloud/virt environments,
# and because this impedes forensics, we are differing from the Fedora
# default of having /tmp on tmpfs.
echo "Disabling tmpfs for /tmp."
systemctl mask tmp.mount >> /root/ks-post.debug.log 2&>1

# utility script
echo -n "Utility scripts"
echo "== Utility scripts ==" >> /root/ks-post.debug.log
wget -O /opt/domu-hostname.sh https://github.com/frederickding/xenserver-kickstart/raw/develop/opt/domu-hostname.sh 2>> /root/ks-post.debug.log
chmod +x /opt/domu-hostname.sh
echo .

# remove unnecessary packages
echo -n "Removing unnecessary packages"
echo "== Removing unnecessary packages ==" >> /root/ks-post.debug.log
yum -C -y remove linux-firmware >> /root/ks-post.debug.log 2&>1
yum -C -y groups mark convert >> /root/ks-post.debug.log 2&>1
yum -C -y groups remove hardware-support >> /root/ks-post.debug.log 2&>1
echo .

# generalization
echo -n "Generalizing"
rm -f /etc/ssh/ssh_host_*
echo .

# fix boot for older pygrub/XenServer
# you should comment out this entire section if on XenServer Creedence/Xen 4.4
echo -n "Fixing boot"
echo "== GRUB fixes ==" >> /root/ks-post.debug.log
cp /boot/grub2/grub.cfg /boot/grub2/grub.cfg.bak
cp /etc/default/grub /etc/default/grub.bak
cp --no-preserve=mode /etc/grub.d/00_header /etc/grub.d/00_header.bak
sed -i 's/GRUB_DEFAULT=saved/GRUB_DEFAULT=0/' /etc/default/grub
sed -i 's/default="\\${next_entry}"/default="0"/' /etc/grub.d/00_header
echo -n "."
grub2-mkconfig -o /boot/grub2/grub.cfg >> /root/ks-post.debug.log 2&>1
echo .

echo -n "Cleaning old yum repodata"
echo "== yum clean-up ==" >> /root/ks-post.debug.log
yum history new >> /root/ks-post.debug.log 2&>1
yum clean all >> /root/ks-post.debug.log 2&>1
truncate -c -s 0 /var/log/yum.log
echo .

echo -n "Importing RPM GPG key"
echo "== RPM GPG key ==" >> /root/ks-post.debug.log
releasever=$(rpm -q --qf '%{version}\n' fedora-release)
basearch=$(uname -i)
rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-$releasever-$basearch >> /root/ks-post.debug.log 2&>1
echo .
%end