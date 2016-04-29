#!/bin/bash

# for Debian/Ubuntu systems only
# CentOS/Fedora systems should automatically regenerate on boot
[ ! -f /etc/ssh/ssh_host_rsa_key ] && dpkg-reconfigure openssh-server