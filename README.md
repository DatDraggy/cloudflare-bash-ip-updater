# Cloudflare IP Updater in Bash
This small script updates your IPv4 and IPv6 records in your cloudflare account

If you have a dynamic ip address, you can make cronjob execute this file every 5 minutes.
It then checks if the current address is the same as the one in cloudflare

If you have multiple domains pointing to the same server, you can simply point a "CNAME" record to the domain in zone_name.