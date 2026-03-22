Viewing Local Network Status

(a) List active TCP connections

On Windows, an appropriate command is:

netstat -ano


or, if you only wants established connections:

netstat -ano | find "TCP"


This displays all active TCP connections, with local and remote addresses/ports, state, and the owning process ID.[2][1]

Help can be available from:

netstat /help


A typical excerpt of the output (your numbers and addresses will differ) looks like:

Proto  Local Address          Foreign Address        State           PID
TCP    192.168.1.10:49753     172.217.24.14:443      ESTABLISHED     908
TCP    192.168.1.10:49754     172.217.24.14:443      ESTABLISHED     908
TCP    0.0.0.0:135            0.0.0.0:0              LISTENING       968
TCP    [::]:49755             [::]:0                 LISTENING       1234


You should run the command above in Command Prompt or PowerShell and paste your real output where your assignment asks for it.[1][2]

Brief explanation of the requested columns:

Local address: The IP address and port on your machine that the connection is using (for example, 192.168.1.10:49753 or 0.0.0.0:135).[2][1]

Foreign address: The remote IP address and port to which your machine is connected, or from which it is listening for connections (for example, 172.217.24.14:443).[1][2]

State: The current state of the TCP connection, such as LISTENING (waiting for connections), ESTABLISHED (an active connection is open), TIME_WAIT, CLOSE_WAIT, etc.[4][2][1]



(b) View network interfaces and extract info

On Windows, a standard command to show the status of all network interfaces is:

ipconfig /all


Help can be available from:

Ipconfig /help

This lists each adapter (Ethernet, Wi‑Fi, virtual adapters, etc.) with its IPv4 address, MAC address (“Physical Address”), and other details.[5][6][7][3]

A shortened, schematic example (you must use your own real output):

Ethernet adapter Ethernet:

   Connection-specific DNS Suffix  . :
   Description . . . . . . . . . . . : Intel(R) Ethernet Connection
   Physical Address. . . . . . . . . : 00-1A-2B-3C-4D-5E
   DHCP Enabled. . . . . . . . . . . : Yes
   IPv4 Address. . . . . . . . . . . : 192.168.1.20(Preferred)
   Subnet Mask . . . . . . . . . . . : 255.255.255.0

Wireless LAN adapter Wi-Fi:

   Connection-specific DNS Suffix  . :
   Description . . . . . . . . . . . : Intel(R) Dual Band Wireless-AC
   Physical Address. . . . . . . . . : 11-22-33-44-55-66
   DHCP Enabled. . . . . . . . . . . : Yes
   IPv4 Address. . . . . . . . . . . : 192.168.1.30(Preferred)
   Subnet Mask . . . . . . . . . . . : 255.255.255.0


For example, maybe from your real ipconfig /all output, do the following.[6][7][3][5]

Identify which Wi‑Fi adapter section (usually “Wireless LAN adapter Wi‑Fi”) and which Ethernet adapter section (“Ethernet adapter Ethernet” or similar) are actually connected (they will show an IPv4 address instead of “Media disconnected”).[7][3][5][6]

For each of those two adapters, note:

Interface name (e.g., Wi-Fi, Ethernet).

The IPv4 Address line.

The Physical Address line (MAC).

Then summarise in a table like this (filling in your real values):

Connection type

Interface name

IPv4 address (from ipconfig /all)

MAC address (Physical Address)

Wi‑Fi

Wi-Fi

192.168.1.30

11-22-33-44-55-66

Ethernet

Ethernet

192.168.1.20

00-1A-2B-3C-4D-5E




Reference:



https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/netstat      

https://www.windowscentral.com/how-use-netstat-command-windows-10      

https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/ipconfig    

https://stackit.news.blog/2021/07/20/checking-active-tcp-ip-connections-on-windows-with-powershell/ 

https://mundobytes.com/en/How-to-list-all-network-interfaces-in-cmd/   

https://commandmasters.com/commands/ipconfig-windows/   

https://blog.csdn.net/cunjiu9486/article/details/109074353   

https://blog.csdn.net/cunjiu9486/article/details/109075211 

https://quickbytesstuff.blogspot.com/2015/10/show-interface-ip-address-in-windows-10.html 

https://stackoverflow.com/questions/48198/how-do-i-find-out-which-process-is-listening-on-a-tcp-or-udp-port-on-windows 

https://kevincurran.org/com320/labs/netstat.html 

https://blog.marcnuri.com/how-to-check-open-ports-in-windows 

https://stackoverflow.com/questions/27160042/get-interface-name-ip-and-mac-in-windows-command-line 

https://stackoverflow.com/questions/20882/how-do-i-interpret-netstat-a-output 

https://community.intersystems.com/post/it-possible-get-list-all-active-open-tcpip-connections-made-iris