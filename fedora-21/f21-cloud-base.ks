# Fedora 21 Cloud Base kickstart for XenServer
# branch: develop
##########################################

# Install, not upgrade
install

# Install from a friendly mirror and add updates
url --mirrorlist=http://mirrors.fedoraproject.org/mirrorlist?repo=fedora-21&arch=$basearch
# repo --name=fedora --mirrorlist=http://mirrors.fedoraproject.org/mirrorlist?repo=fedora-$releasever&arch=$basearch
repo --name=updates --mirrorlist=http://mirrors.fedoraproject.org/mirrorlist?repo=updates-released-f$releasever&arch=$basearch

# Language and keyboard setup
lang en_US.UTF-8
keyboard us

# Configure networking without IPv6, firewall off, DHCP
network --bootproto=dhcp --device=link --activate --onboot=on

firewall --disabled

# Set timezone
timezone --utc Etc/UTC

# Authentication
rootpw --lock --iscrypted locked

# User will be defined by cloud-init
user --name=none

# SELinux enabled
selinux --enforcing

# Enable cloud image services
services --enabled=network,sshd,rsyslog,cloud-init,cloud-init-local,cloud-config,cloud-final

# Disable anything graphical
skipx
text

# Setup the disk
clearpart --none
part biosboot --fstype=biosboot --size=1
part /boot --fstype=ext3 --size=500
part / --fstype=ext4 --grow --size=3000
bootloader --timeout=50 --driveorder=xvda --append="no_timer_check console=hvc0" --extlinux

# Shutdown when the kickstart is done
halt

# Set up GPT partitions
%pre
parted -s /dev/xvda mklabel gpt
%end

# Minimal package set
%packages --excludedocs

# as of Fedora 21, we build a Fedora Cloud product
kernel-core
@^cloud-product-environment
deltarpm
yum-plugin-fastestmirror
-dracut-config-rescue
-biosdevname
-plymouth
-NetworkManager
-iprutils
-kbd
-uboot-tools
-kernel
-grub2
-fprintd-pam
-wireless-tools
%end

# Copy grub.cfg to a backup and then make adaptations for buggy pygrub
%post --log=/root/ks-post.log

# remove the user anaconda forces us to make
userdel -r none

# setup systemd to boot to the right runlevel
echo -n "Setting default runlevel to multiuser text mode"
rm -f /etc/systemd/system/default.target
ln -s /lib/systemd/system/multi-user.target /etc/systemd/system/default.target
echo .

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
ln -s /dev/null /etc/udev/rules.d/80-net-setup-link.rules
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
echo "."

# Because memory is scarce resource in most cloud/virt environments,
# and because this impedes forensics, we are differing from the Fedora
# default of having /tmp on tmpfs.
echo "Disabling tmpfs for /tmp."
systemctl mask tmp.mount

# make sure firstboot doesn't start
echo "RUN_FIRSTBOOT=NO" > /etc/sysconfig/firstboot

# utility script
echo -n "Utility scripts"
echo "== Utility scripts ==" >> /root/ks-post.debug.log
wget -O /opt/domu-hostname.sh https://rawgit.com/frederickding/xenserver-kickstart/develop/opt/domu-hostname.sh 2>> /root/ks-post.debug.log
chmod +x /opt/domu-hostname.sh
echo .

# remove unnecessary packages
echo -n "Removing unnecessary packages"
echo "== Removing unnecessary packages ==" >> /root/ks-post.debug.log
yum -C -y remove linux-firmware >> /root/ks-post.debug.log 2&>1
yum -C -y groups mark convert >> /root/ks-post.debug.log 2&>1
yum -C -y groups remove hardware-support >> /root/ks-post.debug.log 2&>1
echo .

# Remove firewalld
echo -n "- removing firewalld"
yum -C -y remove "firewalld*" --setopt="clean_requirements_on_remove=1" >> /root/ks-post.debug.log 2&>1
echo .

# Another one needed at install time but not after that, and it pulls
# in some unneeded deps (like, newt and slang)
echo -n "- removing authconfig"
yum -C -y remove authconfig --setopt="clean_requirements_on_remove=1" >> /root/ks-post.debug.log 2&>1
echo .

# From spin-kickstarts fedora-cloud-base.ks
echo -n "Getty fixes"
# although we want console output going to the serial console, we don't
# actually have the opportunity to login there (actually, this isn't quite 
# true on Xen -- `xl console`).
# we don't really need to auto-spawn _any_ gettys.
sed -i '/^#NAutoVTs=.*/ a\
NAutoVTs=0' /etc/systemd/logind.conf
echo .

# generalization
echo -n "Generalizing"
rm -f /etc/ssh/ssh_host_*
rm -f /var/lib/random-seed
echo .

# GRUB fixes not needed!

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

echo "Packages within this cloud image:" >> /root/installed-software.log
echo "-----------------------------------------------------------------------" >> /root/installed-software.log
rpm -qa >> /root/installed-software.log
echo "-----------------------------------------------------------------------" >> /root/installed-software.log
# Note that running rpm recreates the rpm db files which aren't needed/wanted
rm -f /var/lib/rpm/__db*

echo -n "Fixing SELinux contexts"
touch /var/log/cron
touch /var/log/boot.log
mkdir -p /var/cache/yum
chattr -i /boot/extlinux/ldlinux.sys >> /root/ks-post.debug.log
/usr/sbin/fixfiles -R -a restore >> /root/ks-post.debug.log
chattr +i /boot/extlinux/ldlinux.sys >> /root/ks-post.debug.log
echo .

echo -n "Zeroing out empty space"
# This forces the filesystem to reclaim space from deleted files
dd bs=1M if=/dev/zero of=/var/tmp/zeros || :
rm -f /var/tmp/zeros
echo .
echo "(Don't worry -- that out-of-space error was expected.)"

%end