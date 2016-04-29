# CentOS 6.7 kickstart for XenServer
# branch: develop
##########################################

# Install, not upgrade
install

# Install from a friendly mirror and add updates
url --url http://mirrors.ukfast.co.uk/sites/ftp.centos.org/6.7/isos/x86_64/
repo --name=centos-updates --mirrorlist=http://mirrorlist.centos.org/?release=6.7&arch=x86_64&repo=updates

# Language and keyboard setup
lang en_GB.UTF-8
keyboard --vckeymap=uk --xlayouts='gb'

# Configure networking without IPv6, firewall off

# for STATIC IP: uncomment and configure
# network --onboot=yes --device=eth0 --bootproto=static --ip=192.168.###.### --netmask=255.255.255.0 --gateway=192.168.###.### --nameserver=###.###.###.### --noipv6 --hostname=$$$

# for DHCP:
network --bootproto=dhcp --device=eth0 --onboot=on

firewall --enabled --ssh

# Set timezone
timezone Europe/London --isUtc

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

# Setup the disk
zerombr
clearpart --all --drives=xvda
part / --fstype=ext4 --grow --size=1024 --asprimary
bootloader --location=partition --timeout=5 --driveorder=xvda --append="console=hvc0"

# Shutdown when the kickstart is done
halt

# Minimal package set
%packages --excludedocs
@server-platform
@network-file-system-client
man
wget
nano
vim
deltarpm
yum-plugin-fastestmirror
net-tools
%end
