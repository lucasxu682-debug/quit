ARP and Local Address Mapping 


(a) Resolve www.google.com and reasons for multiple IPs

Command to find IP addresses

In Command Prompt (or PowerShell):

nslookup www.google.com


This queries DNS and returns one or more IP addresses associated with www.google.com.[3][1]

Example (your output will differ):

C:\>nslookup www.google.com
Server:  8.8.8.8
Address: 8.8.8.8

Non-authoritative answer:
Name:    www.google.com
Addresses: 142.250.66.196
           142.250.66.228
           142.250.66.164


Pay attention to  all resolved IPv4 addresses you see above, e.g.:

142.250.66.196

142.250.66.228

142.250.66.164

Why one hostname maps to multiple IPs

Load balancing and performance: Big services like Google distribute incoming traffic across multiple servers and data centers, so DNS returns several IPs and clients can reach less‑loaded servers, improving response time and scalability.[4][5][6][7]

Redundancy and high availability: Multiple IPs mean that if one server or path fails, clients can connect to another IP for the same hostname, increasing reliability and fault tolerance.[5][8][9][7][4]

Geographic distribution / anycast: users in different regions may be directed to different nearby IPs for the same hostname to reduce latency.[8][9][7][5]

(b) Display ARP cache, explain its role, and identify entries

Command to show ARP cache

In Command Prompt:

arp -a


This displays your system’s ARP cache: mappings between IPv4 addresses and MAC (physical) addresses per interface.[2][10][11]

Example excerpt (your output will differ):

C:\>arp -a

Interface: 192.168.1.50 --- 0x10
  Internet Address      Physical Address      Type
  192.168.1.1           00-11-22-33-44-55     dynamic
  192.168.1.20          3c-52-82-aa-bb-cc     dynamic
  192.168.1.255         ff-ff-ff-ff-ff-ff     static


Role and importance of the ARP cache

You can explain something like:

The ARP cache stores recently learned mappings between IPv4 addresses and MAC addresses for hosts on the local network segment.[10][2]

When your computer needs to send an IP packet to a local IP (such as the default gateway or another LAN host), it looks up the MAC in the ARP cache instead of broadcasting an ARP request every time.[2][10]

This reduces broadcast traffic, lowers latency, and makes local network communication more efficient and reliable.[10][2]

Default gateway IP and MAC from ARP output

From earlier questions (or from ipconfig), you know your default gateway IP address (e.g. 192.168.1.1).[12][13]

In the arp -a output:

Find the line where “Internet Address” equals the default gateway IP.[11][10]

The corresponding “Physical Address” on that line is the MAC address of the default gateway.[11][2][10]

Using the earlier sample:

Default gateway IP: 192.168.1.1

Default gateway MAC: 00-11-22-33-44-55

You must replace these with the values from your own ARP table and clearly state them.

Types of ARP entries: static vs dynamic

In the ARP table, the last column “Type” typically shows dynamic or static.[14][2][10]

Dynamic entries:

Learned automatically using ARP when your host exchanges traffic with another device.

They age out after a timeout if not used.[14][10]

Static entries:

Manually configured (e.g. with arp -s) or created by the system for special addresses (such as broadcast).[15][2][10][14]

They do not age out automatically and stay until removed or rebooted.[10][14]

In your answer, point out at least one dynamic line and (if present) any static lines, and label which is which, using the real entries you see in your arp -a output.[2][14][10]



Reference



https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/nslookup  

https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/arp         

https://www.linode.com/docs/guides/how-to-use-nslookup-command/ 

https://www.reddit.com/r/dns/comments/vs1sbi/whats_the_trick_multiple_ips_one_hostname/  

https://arxiv.org/html/2503.14351v1   

https://www.youtube.com/watch?v=-2WnHiKPrgE 

https://johnmillerus.hashnode.dev/understanding-googles-ip-address-a-comprehensive-guide   

https://www.reddit.com/r/networking/comments/au3mx0/im_a_networking_professional_and_have_a_really/  

https://www.ripe.net/publications/docs/ripe-393/  

https://www.meridianoutpost.com/resources/articles/command-line/arp.php           

https://www.itsyourip.com/networking/arp-to-display-arp-cache-in-windows/   

https://kb.wisc.edu/helpdesk/562 

https://kb.wisc.edu/helpdesk/page.php?id=562 

https://www.gauthmath.com/solution/PtOpdeZgbFF/A-PC-is-configured-to-obtain-an-IP-address-automatically-from-the-network-The-ne     

https://www.studocu.com/en-us/messages/question/10788187/answer-number-3a-pc-is-configured-to-obtain-an-ipv4-address-automatically-from-network 

https://learningnetwork.cisco.com/s/question/0D53i00000KsrGDCAZ/why-does-nslookup-returning-different-ip-addresses 

https://stackoverflow.com/questions/666510/under-what-conditions-with-nslookup-and-ping-return-different-ip-addresses-on-wi 

https://support.alcadis.nl/Support_files/Alcatel-Lucent/OmniSwitch/End of Sale products/OS6400 - EOL/Manuals/OS6400 AOS 6.4.5 R02/OS6400 AOS 6.4.5 R02 CLI Reference Guide.pdf.pdf?_wpnonce=beaea42f5b 

https://www.h3c.com/cn/d_202205/1608678_30005_0.htm