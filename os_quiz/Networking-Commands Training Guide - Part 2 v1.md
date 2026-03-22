Routing and Name Resolution

(a) View IPv4 routing table

Command and output

In Command Prompt (cmd) on Windows, use either of:

route print -4


or

netstat -r -4


route print -4 shows the IPv4 routing table with destination, netmask, gateway, interface and metric.[2][1]

A typical excerpt looks like (your values will differ; you must paste your real output):

===========================================================================
IPv4 Route Table
===========================================================================
Active Routes:
Network Destination Netmask         	Gateway       Interface      Metric
  0.0.0.0		0.0.0.0		192.168.1.1   192.168.1.50     25
  127.0.0.0        	255.0.0.0        	On-link       127.0.0.1       331
  127.0.0.1  		255.255.255.255     On-link       127.0.0.1       331
  192.168.1.0    	255.255.255.0       On-link  	 192.168.1.50    281
  192.168.1.50  	255.255.255.255     On-link    	 192.168.1.50    281
  192.168.1.255 	255.255.255.255     On-link    	 192.168.1.50    281


From the above results, identify the following.

Identify requested routes

From the Active Routes section of the IPv4 table:[1][2][5]

Default route:

Row where Network Destination is 0.0.0.0 and Netmask is 0.0.0.0.

Example: 0.0.0.0   0.0.0.0   192.168.1.1   192.168.1.50   25.

So in this example:

Destination: 0.0.0.0

Netmask: 0.0.0.0

Gateway: 192.168.1.1

Metric: 25

On-link : “They are addresses that can be resolved locally. They don't need a gateway because they don't need to be routed.”. Take a look here: What does "On-link" mean on the result of "route print" command?



Route used for your local network:

Look for the row whose Network Destination and Netmask correspond to your LAN, typically something like 192.168.1.0 with 255.255.255.0.[2][5]

Example: 192.168.1.0 255.255.255.0 On-link 192.168.1.50 281.

So in this example:

Destination: 192.168.1.0

Netmask: 255.255.255.0

Metric associated with default route:

This is the Metric value in the default route row (e.g. 25 in the example above).[6][1][2]

Brief explanation of the metric

The metric is a cost value that the system uses when choosing between multiple possible routes to the same destination.[6][1][2]

Lower metric values are preferred; the route with the lowest metric for a matching destination is selected.[5][1][2][6]

On Windows, metrics can be set automatically based on interface speed and other factors, so faster or more preferred interfaces get lower metrics.[7][8][1]

In your answer, explicitly quote the values you see in your own table, for example:

Default route: destination 0.0.0.0, netmask 0.0.0.0, gateway 192.168.1.1, metric 25.

Local network route: destination 192.168.1.0, netmask 255.255.255.0.



(b) Display and renew DHCP lease

Commands

Use ipconfig to display and then renew your DHCP lease.[3][4][9][10]

Help is available from:

ipconfig /help


Show full network and DHCP information:

ipconfig /all


Release current lease:

ipconfig /release


Renew the lease:

ipconfig /renew


These commands first show your current addresses and DHCP lease details, then drop the lease and request a new one from the DHCP server.[4][9][10][3]

What to document

From the initial ipconfig /all output, for the adapter you are using (Wi‑Fi or Ethernet), record at least:[9][3][4]

IPv4 Address.

Subnet Mask.

Default Gateway.

DHCP Server.

Lease Obtained.

Lease Expires.

Run ipconfig /all, then ipconfig /release, then ipconfig /renew, and ipconfig /all again.[10][3][4][9]

Paste the relevant parts of the before and after outputs into your answer, then note any changes such as:[3][4][10]

Did the IPv4 address stay the same or change?

Did the default gateway or DHCP server change?

Did the “Lease Obtained” and “Lease Expires” timestamps update?

For example, your documentation could look like:

Before renew (from ipconfig /all):

IPv4 Address: 192.168.1.30

DHCP Server: 192.168.1.1

Lease Obtained: 07 March 2026 22:10:23

Lease Expires: 08 March 2026 22:10:23

After ipconfig /release and ipconfig /renew and running ipconfig /all again:

IPv4 Address: 192.168.1.30 (unchanged, for example)

Lease Obtained: 07 March 2026 23:31:02 (updated)

Lease Expires: 08 March 2026 23:31:02 (updated)

This shows that your DHCP lease was renewed and the lease times were reset, even if the IP address itself did not change.[4][10][3]



Additional Information:



Try using the following:



netsh interface ip show config





Reference:



https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/route_ws2008       

https://www.simplified.guide/microsoft-windows/ip-route-show       

https://kb.wisc.edu/helpdesk/562       

https://kb.wisc.edu/helpdesk/page.php?id=562       

https://blog.csdn.net/yimenglin/article/details/107182025   

https://nieyong.github.io/wiki_ny/理解Windows中的路由表和默认网关.html   

https://learn.microsoft.com/en-us/troubleshoot/windows-server/networking/automatic-metric-for-ipv4-routes 

https://shazi.info/windows-route-網路卡的計量自動公制設定－兩組-gateway-並行/ 

https://www.youtube.com/watch?v=azJB39At_u4    

https://computing.cs.cmu.edu/desktop/ip-renew     

https://community.spiceworks.com/t/static-route-metric-1-vs-default-what-is-the-difference/782427 

https://www.youtube.com/watch?v=2L8oPYkw26M 

https://www.dummies.com/article/technology/information-technology/networking/general-networking/network-administration-displaying-the-routing-table-184340/ 

https://www.dummies.com/article/network-administration-displaying-the-routing-table-184340 

https://www.reddit.com/r/sysadmin/comments/v45qvb/force_the_dhcp_server_to_renew_the_ip_address/