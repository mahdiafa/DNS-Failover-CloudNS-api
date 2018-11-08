#!/bin/bash
# Date: 2018-05-25
# Written by: Mahdi Afazeli
# Modify by: Mahdi Afazeli 2018-05-25

# Check the availabilty of website by ICMP and HTTP(S) to deactive unreachable host.
# This script check the A record that you entered in $3 argument to make sure your server with IP address ($1) is up and reachable.
# also you can leave $3 alone if you have to check A records of yur domain without any subdomain name 
# the server that you want to monitor must be pingable from where you run this script

time=$(date '+%F %T')
dir=$(dirname $0)
logfile="$dir"/logs
recordcheckurl="https://api.cloudns.net/dns/records.json"
changerecordurl="https://api.cloudns.net/dns/change-record-status.json"
authid="your-authid" # change it to your authid
authpass="your-authpass" # change it to your authpass
host="$3" # second argument
domain="$2" # third argument
web="443"
maillist="your-admin@domain.com"

mkdir -p $dir/records
# Remove old records
rm -f $dir/records/* 

# Get records and write it to the file with id number name
for id in $(curl -s $recordcheckurl -d "auth-id=$authid&auth-password=$authpass&domain-name=$domain&host$host&type=a" | jq -r .[].id); do echo $(curl -s $recordcheckurl -d "auth-id=$authid&auth-password=$authpass&domain-name=$domain&host$host&type=a" | jq -r '."'$id'".record') > records/$id; done

# Get IP address of the record
for id in $(curl -s $recordcheckurl -d "auth-id=$authid&auth-password=$authpass&domain-name=$domain&host$host&type=a" | jq -r .[].id); do ip=$(cat $dir/records/$id | grep $1); done

# Find status of the record
for id in $(curl -s $recordcheckurl -d "auth-id=$authid&auth-password=$authpass&domain-name=$domain&host$host&type=a" | jq -r .[].id); do status=$(curl -s $recordcheckurl -d "auth-id=$authid&auth-password=$authpass&domain-name=$domain&host$host&type=a" | jq -r '."'$id'".status'); done

fping $1
if [ $? -eq 0 ] # Ping hosts
then
	echo $time IP:$1 by ICMP is reachable >> $logfile
	exit 0
else
	echo $time IP:$1 by ICMP is unreachable >> $logfile
	nc -z -w5 $1 $web # Check web reachable
	if [ $? -eq 0 ]
	then
		echo $time Web service on $1 is up and running >> $logfile
		exit 0
	else
		echo $time Web service on $1 is also down >> $logfile
		curl -s $recordcheckurl -d "auth-id=$authid&auth-password=$authpass&domain-name=$domain&host$host&type=a" | jq  '.[].record' | grep $1 # Get records of domain
		if [ $? -eq 1 ]
		then
        		echo $time record for IP $1 is unavailable >> $logfile
        		exit 2
		else
        		echo $time record for IP $1 is available on cloudns >> $logfile
        		echo $time end of check availability >> $logfile
			echo $time we have to change status of record to 0 to deactive >> $logfile
				
			echo $time starting deactivation >> $logfile
			if [ "$ip" != "$1" ] # check records and IP of host
			then
        			echo $ip >> $logfile
				echo $time record is unavailable >> $logfile
        			exit 0
			elif [ "$status" = 0 ]
			then
				echo $time record is deactive >> $logfile
				exit 0
			else
        			echo $time record is available and active >> $logfile
        			echo $time record id is $id >> $logfile
        			curl -s $changerecordurl -d "auth-id=$authid&auth-password=$authpass&domain-name=$domain&record-id=$id&status=0" # Disable the record on CloudNS
				echo -e "Dear sysadmin\\nPleased be informed that DNS record related to "$2"."$3" with IP address $1 and ID $id deactivated.\\nPlease check availability of url and sever to make sure it is up and ready to service\\nRegards,\\n" | mail -s "$1 of "$2"."$3" deactivated" $maillist	
        			echo
        			echo $time end of deactivation
        			echo
			fi
        		exit 0
		fi
	fi
fi
