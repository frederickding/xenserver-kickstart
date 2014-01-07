# Install, not upgrade
install

# Install from a friendly mirror and add updates
url --mirrorlist=http://mirrors.fedoraproject.org/mirrorlist?repo=fedora-20&arch=$basearch
repo --name=updates

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
rootpw Asdfqwerty
# if you want to preset the root password in a public kickstart file, use SHA512crypt e.g.
# rootpw --iscrypted $6$9dC4m770Q1o$FCOvPxuqc1B22HM21M5WuUfhkiQntzMuAV7MY0qfVcvhwNQ2L86PcnDWfjDd12IFxWtRiTuvO/niB0Q3Xpf2I.
authconfig --enableshadow --passalgo=sha512

# SELinux enabled
selinux --enabled

# Disable anything graphical
skipx
text

# Setup the disk
zerombr
clearpart --all --drives=xvda
part / --fstype=ext3 --grow --size=1024 --asprimary
bootloader --location=partition --timeout=5 --driveorder=xvda --append="console=hvc0"

# Shutdown when the kickstart is done
halt

# Minimal package set
%packages --excludedocs
@standard
man
vim
deltarpm
yum-plugin-fastestmirror
realmd
net-tools
-dracut-config-rescue
-fprintd-pam
-wireless-tools
%end

# Add in an old-style menu.lst to make XenServer's pygrub happy
# and disable the GRUB2 configuration file
%post
mkdir /boot/grub
KERNELSTRING=`rpm -q kernel --queryformat='%{VERSION}-%{RELEASE}.%{ARCH}\n' | tail -n 1`

cat > /boot/grub/grub.conf <<EOF
default=0
timeout=5
title Fedora (${KERNELSTRING})
	root (hd0,1)
	kernel /boot/vmlinuz-${KERNELSTRING} ro root=/dev/xvda1 console=hvc0 quiet
	initrd /boot/initramfs-${KERNELSTRING}.img
EOF
ln -s /boot/grub/grub.conf /boot/grub/menu.lst
ln -s /boot/grub/grub.conf /etc/grub.conf
mv /boot/grub2/grub.cfg /boot/grub2/grub.cfg.bak
%end