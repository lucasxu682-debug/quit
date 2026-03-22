Reachability

1. Test reachability of www.google.com and explain TTL

Command, example output, and reachability

In Windows Command Prompt:

ping www.google.com


This sends ICMP Echo Requests to www.google.com and shows whether replies are received.[2][3][1]

Example (your actual output will differ):

C:\>ping www.google.com

Pinging www.google.com [142.250.66.196] with 32 bytes of data:
Reply from 142.250.66.196: bytes=32 time=22ms TTL=115
Reply from 142.250.66.196: bytes=32 time=21ms TTL=115
Reply from 142.250.66.196: bytes=32 time=23ms TTL=115
Reply from 142.250.66.196: bytes=32 time=22ms TTL=115

Ping statistics for 142.250.66.196:
    Packets: Sent = 4, Received = 4, Lost = 0 (0% loss),
Approximate round trip times in milli-seconds:
    Minimum = 21ms, Maximum = 23ms, Average = 22ms


From such an output you would state: the host is reachable because all 4 echo requests received replies and packet loss is 0%. If your output shows only Request timed out (4 sent, 0 received, 100% loss), then you would state that the host is not reachable (or ICMP is being blocked) based on these results.

Meaning of the TTL value

Each reply line includes TTL=..., e.g. TTL=115.[4][5][1]

You can explain:

TTL (Time to Live) is an IP header field that sets the maximum number of router hops a packet can traverse before being discarded.[6][5][7][4]

The sender sets an initial TTL (for example 64 or 128); each router along the path decrements it by 1, and if TTL reaches 0 the packet is dropped and an ICMP “Time Exceeded” message is generated.[5][7][4][6]

The TTL value shown in the ping reply is the remaining TTL when the reply reaches your computer, which indirectly reflects how many hops it passed through from the original starting value.[8][4][6][5]

You can phrase it briefly: “TTL shows how many more router hops the packet could take before being discarded; each router decreases it by one, so it prevents packets from circulating indefinitely.”



2. Default echo count and sending 15 requests

Default number of echo requests

On Windows, the basic ping command sends 4 echo requests by default if you don’t specify a count.[9][1][10][2]

This is documented in the ping help: parameter /n <count> “specifies the number of echo Request messages” and “the default is 4.”[1]

So for your answer, state that the default number of echo requests is 4, and you can point to your original ping www.google.com output, which will show four reply lines and statistics “Sent = 4”.

Modified command to send 15 echo requests

To send 15 requests, use the /n (or -n) option:

ping www.google.com -n 15


(or ping -n 15 www.google.com — order doesn’t matter).[11][12][1]

Example of (truncated) output:

C:\>ping www.google.com -n 15

Pinging www.google.com [142.250.66.196] with 32 bytes of data:
Reply from 142.250.66.196: bytes=32 time=22ms TTL=115
...
Reply from 142.250.66.196: bytes=32 time=24ms TTL=115

Ping statistics for 142.250.66.196:
    Packets: Sent = 15, Received = 15, Lost = 0 (0% loss),
Approximate round trip times in milli-seconds:
    Minimum = 21ms, Maximum = 27ms, Average = 23ms


In your interpretation of the 15‑ping run, comment on:

Reachability and reliability: e.g. 15 sent, 15 received, 0% loss → host is reachable and the connection is reliable.

Latency: use the min/avg/max, e.g. “average RTT about 23 ms, low variation, so latency is stable.”

Any anomalies: if some packets are lost or there is high variation in times, note that this could indicate congestion, transient network issues, or variable routing.[13][9]



Reference



https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/ping      

https://admiralmarketsjordan.freshdesk.com/en/support/solutions/articles/201000119023-how-to-do-a-ping-test-on-a-windows   

https://www.ionos.com/digitalguide/server/tools/ping-command/ 

http://www.hkjs.com/m_news/3442.html    

https://ostechnix.com/identify-operating-system-ttl-ping/    

https://www.linkedin.com/pulse/exploring-time-to-live-ttl-value-ping-responses-viral-parmar-5wn2f   

https://www.imperva.com/learn/performance/time-to-live-ttl/  

https://www.reddit.com/r/networking/comments/164t69s/trying_to_understand_ttl/ 

https://blog.invgate.com/ping-command  

https://netbeez.net/blog/ping/ 

https://ping-test.net/mastering_ping_command_options_and_parameters 

https://www.omnisecu.com/tcpip/how-to-specify-the-number-of-packets-sent-ping-command.php 

https://www.kentik.com/kentipedia/ping-command-in-network-troubleshooting-and-monitoring/ 

https://www.layerstack.com/resources/tutorials/how-to-enable-disable-ping-windows-server-2025-firewall 

https://www.youtube.com/watch?v=BNykcxWEfXw 

https://stackoverflow.com/questions/36671030/how-to-grab-ipv4-variable-in-cmd-and-ping-in-new-cmd-window 

https://www.youtube.com/watch?v=DxBoQgPCNsU 

https://www.youtube.com/watch?v=nLRXG4G7sfo