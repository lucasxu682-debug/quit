When to use netstat, ipconfig, route, ARP, nslookup, ping, tracert, etc. networking commands on Windows?

Use each command at a specific step of troubleshooting or inspection; think “from local config, to basic reachability, to path, to name resolution, to ARP, to routes, to sockets.”

Quick “when to use what” overview

Goal / situation

Command(s) to use

See my IP, mask, gateway, DNS

ipconfig / ipconfig /all [1][2]

Check if a host is reachable at all

ping [1][3]

See the path (which routers) to a host

tracert [4][1]

Test/inspect DNS name ↔ IP

nslookup [1][5]

See local TCP/UDP connections and listening ports

netstat (e.g. netstat -an) [4][6]

See routing table, default gateway behavior

route print (or netstat -r) [7][6]

See/clear IP→MAC mappings on the LAN

arp -a, arp -d [4][1]



ipconfig

Use when you need to:

Confirm your own IP address, subnet mask, default gateway, and DNS servers (e.g. “Do I even have an address? Is it from the right network?”).[1][2]

Check DHCP vs static, or see if you picked up an APIPA address (169.254.x.x) indicating DHCP failure.[1]

Typical first command in almost any Windows network issue.

ping

Use when you want to:

Test basic connectivity and latency to another IP or hostname (e.g. ping 8.8.8.8, ping www.google.com).[3][1]

Differentiate local vs wider issues (e.g. ping gateway, then ISP DNS, then Internet host).[1]

If ping to gateway fails, suspect local network; if gateway works but Internet host fails, suspect routing or DNS.

tracert

Use when:

Ping works intermittently or not at all and you want to see where along the path packets are lost or delayed.[4][1]

You’re diagnosing routing or ISP issues (e.g. tracert www.google.com to see which hop times out).[8][4]

It shows each router hop and Round-Trip Time (RTTs), so you can identify the first problematic hop.

nslookup

Use when:

Hostname resolution is in question: “Is DNS resolving this domain correctly?”[5][1]

You can ping IPs but not domain names, or different hosts resolve to unexpected IPs.[1]

Examples: nslookup www.example.com, or nslookup then specify a different DNS server to test.

netstat

Use when:

You need to see which ports are open and which processes are using them (e.g. “Is my server actually listening on 0.0.0.0:80?”).[6][4]

You want to list active TCP connections, listening sockets, and sometimes routing info (netstat -an, netstat -b, netstat -r).[7][6]

Useful for debugging local services, security (suspicious connections), and port conflicts.

route

Use when:

You need to inspect or debug the routing table on the Windows host, especially default route and more-specific routes.[7][6]

You suspect “wrong gateway” or overlapping networks: route print shows destination networks, gateways, metrics.[7]

For advanced cases you can also add or delete routes (route add, route delete).

ARP

Use when:

You suspect a local LAN problem, like incorrect MAC mappings, or you want to confirm which MAC address corresponds to an IP in your subnet.[4][1]

You want to check for duplicate IPs or ARP cache anomalies: arp -a to view, arp -d to clear entries.[4]

It’s only meaningful for devices on the same L2 segment.



If you imagine a typical “can’t reach a website” problem, you’d usually go in this rough order: ipconfig → ping (gateway, then IP, then name) → tracert → nslookup → route print → arp -a / netstat depending on what you find.



Reference



https://www.ninjaone.com/blog/top-network-commands-you-should-know/             

https://www.geeksforgeeks.org/computer-networks/networking-commands-for-troubleshooting-windows/  

https://python-automation-book.readthedocs.io/en/1.0/appendix/04_windows.html  

https://blog.csdn.net/remwnber/article/details/109081707        

https://www.youtube.com/watch?v=Z3An-33EFpk  

https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/netstat     

https://www.gauthmath.com/solution/1986649989823876/What-command-displays-the-route-table-of-a-Windows-computer-route-view-netstat-r    

https://www.youtube.com/watch?v=AimCNTzDlVo 

https://www.linkedin.com/posts/gokahwilliam_essential-windows-network-commands-boost-activity-7408092208052129792-29FN 

https://www.instagram.com/p/DKbdaSRvA-B/?hl=en 

https://datahacker.blog/industry/technology-menu/networking/routes-and-rules/route-and-netstat 

https://www.namecheap.com/support/knowledgebase/article.aspx/9667/2194/what-are-traceroute-ping-telnet-and-nslookup-commands/ 

https://www.facebook.com/groups/435258026591146/posts/26168164289540500/ 

https://www.tsnien.idv.tw/Manager_WebBook/chap3/3-5 網路常用命令 - Windows.html 

https://www.youtube.com/watch?v=M4yzxOAtn7k