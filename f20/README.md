Fedora 20 XenServer kickstart files
===================================

## Howto

1. Create a new VM in XenCenter using the RHEL 6.0 template. Select 32-bit or 64-bit per your preferences, although these days there are few reasons not to use 64-bit. (Hypothetically, the CentOS 6.0 templates should work too.)
2. Use the Fedora 20 netinst.iso disk image OR boot directly from a Fedora mirror, ensuring that you select an image or URL that matches the architecture of your selected template. For instance, if you selected RHEL 6.0 64-bit, use `Fedora-20-x86_64-netinst.iso` as the disk image. If you are using a mirror, I often use `http://mirrors.mit.edu/fedora/linux/releases/20/Fedora/x86_64/os/`.
3. In **Advanced OS boot parameters**, put 
```
console=hvc0 utf8 nogpt noipv6 ks=https://raw.github.com/frederickding/xenserver-kickstart/master/f20/f20-server.ks
```
(use the *raw* link to the kickstart file; you can also customize the file and store it elsewhere).
4. Give the new machine **at least 1024 MB of RAM**; Anaconda complains if you give it less than something like 924 MB while trying to install without a swap partition. You should be able to decrease this safely after install if you have to. Alternatively, customize the kickstart to assign a swap partition *(untested)*.
5. Use your own settings for vCPUs, storage repository, and networking, ensuring that the VM has at least one functioning network adapter.
6. Finish the wizard and let XenServer boot the VM automatically.