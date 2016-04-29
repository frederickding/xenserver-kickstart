xenserver-kickstart
===================

Kickstart scripts for unattended installation of linux guests with Xenserver for distributions that use Anaconda
Going to need an active Internet Connection and DHCP for providing IP address to booting VPS

1.) Open XenCenter >>> Select Node to Create VPS

2.) Right Click >>> New VM

3.) Select Template for Linux Distribution

4.) Name It

5.) Select Installation Media, You can do it via URL or ISO

6.) Add Raw Github url to Advanced OS Boot Parameters

console=hvc0 utf8 nogpt noipv6 ks=https://raw.githubusercontent.com/frederickding/xenserver-kickstart/master/f20/f20-server.ks

7.) Specificy VPS Location on which NODE, Appropriate CPU, Memory, Network Adapter

8.) Click Finish and Monitor Build from Console
