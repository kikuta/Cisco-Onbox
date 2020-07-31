# Test and Notification automation on-box

Problem: When SIer changes the running-config such as ACL/Vlan/Routing, the reachability test must be done and reported with documentation. The task is always taking time and cost.

Solution: Use On-box Python to test, documentation, and sending the output to alias or SNS. The python script can be initiated by EEM events such as syslog (Syslog ED), timer (Timer ED), or routing change (Routing ED).

# How the script works
![How the script works](./image1.png)

# Configuration
![Configuration](./image2.png)