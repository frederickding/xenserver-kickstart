Fedora 21 XenServer kickstart files
===================================

## Howto for a PVHVM guest

From now on, kickstarts will be developed assuming that the guest domU will 
run as a PVHVM guest. This ensures that the resulting image/VM is adaptable if 
migrated to a different environment. Additionally, with newer kernels and 
virtualization hardware, PVHVM produces better performance. Thus, previous 
instructions and kickstarts that assumed the use of PV guests are now defunct.

After booting from a netinst.io disk image, the Fedora 21 DVD, or an iPXE 
network boot, you should append the parameter
```
ks=http://cdn.rawgit.com/frederickding/xenserver-kickstart/7d89f3e513ebf3ef8c5433b28a0d3d15a7334fcd/fedora-21/f21-server.ks
```
to the bootloader's kernel arguments to utilize the kickstart script.

## Howto for a PV guest

However, if you prefer to install a PV guest, these instructions should still 
work:

1. Create a new VM in XenCenter using the RHEL or CentOS 6.0 template, unless your version of XenCenter has a newer RHEL or CentOS 7 template. Select 32-bit or 64-bit per your preferences, although these days there are few reasons not to use 64-bit.
2. Use the Fedora Server 21 net installer disk image OR boot directly from a Fedora mirror, ensuring that you select an image or URL that matches the architecture of your selected template. For instance, if you selected RHEL 6.0 64-bit, use `Fedora-Server-netinst-x86_64-21` as the disk image. If you are using a mirror, I often use `http://mirrors.mit.edu/fedora/linux/releases/21/Server/x86_64/os/`.
3. In **Advanced OS boot parameters**, put 
```
console=hvc0 utf8 ks=http://cdn.rawgit.com/frederickding/xenserver-kickstart/7d89f3e513ebf3ef8c5433b28a0d3d15a7334fcd/fedora-21/f21-server.ks
```
(use the *raw* link to the kickstart file; you can also customize the file and store it elsewhere).
4. Give the new machine **at least 1024 MB of RAM**; Anaconda complains if you give it less than something like 924 MB while trying to install without a swap partition. You should be able to decrease this safely after install if you have to. Alternatively, customize the kickstart to assign a swap partition *(untested)*.
5. Use your own settings for vCPUs, storage repository, and networking, ensuring that the VM has at least one functioning network adapter.
6. Finish the wizard and let XenServer boot the VM automatically.

## Disclaimer

These scripts are provided as-is with no guarantees.