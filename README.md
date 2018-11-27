# DNS-Failover-CloudNS-api

The script checks the availability of website by ICMP & HTTP(S), if ICMP result shows that the website is unreachable, then the script will check the availability of website by HTTP(S) port request. If both show that the website is down then “A record” will be deactivated on CloudNS by the script.
So that there are 3 arguments in use, $1 is the website IP address, $2 is the domain name (sample.com) and finally $3 is the “A record” (www). However it is also an option to do not use “$3” (A record), it is up to you.  
Keep in mind that website must be pingable from the source where is executing the script.
