#!/bin/bash
# Based on https://github.com/krobertson/xenserver-automater/blob/master/usr/sbin/xe-set-hostname
# Adapted by Frederick Ding

# Detect if xenstore-read is available
XENSTOREREAD=`which xenstore-read`
if [ -e $XENSTOREREAD ]; then
	# Filter the domU's name to a lowercase alphanumeric hyphenated hostname
	NAME=`xenstore-read name | sed -e 's/[^[:alnum:]|-]/-/g' | tr '[:upper:]' '[:lower:]'`

	# Don't do anything if this name is blank
	[ "$NAME" = "" ] && exit 0

	# Set the hostname
	echo "$NAME" > /etc/hostname
	/bin/hostname -F /etc/hostname
fi
exit 0