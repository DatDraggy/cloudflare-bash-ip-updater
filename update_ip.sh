#!/bin/bash

zone_identifier="" #Log in to Cloudflare, select domain, copy "Zone ID" from Overview
auth_key="" #Below "Zone ID", click "Get your API key" and create a token with the "Edit zone DNS" template. Set your zone in "Zone Resources" and create
record_name="" #example.com
ip=$(curl -s v4.ident.me)
ipSix=$(curl -s v6.ident.me)
log_file="/var/log/update_ip.log"
log() {
    if [ "$1" ]; then
        echo -e "[$(date)] - $1" >> $log_file
    fi
}

recordA_ip=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$zone_identifier/dns_records?name=$record_name&type=A" -H "Authorization: Bearer $auth_key" -H "Content-Type: application/json" | jq '.result[0].content' -r)
recordAAAA_ip=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$zone_identifier/dns_records?name=$record_name&type=AAAA" -H "Authorization: Bearer $auth_key" -H "Content-Type: application/json" | jq '.result[0].content' -r)
#Stop when same
if [[ $ip == $recordA_ip ]] && [[ $ipSix == $recordAAAA_ip ]]; then
    exit 0
fi

recordA_identifier=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$zone_identifier/dns_records?name=$record_name&type=A" -H "Authorization: Bearer $auth_key" -H "Content-Type: application/json" | jq '.result[0].id' -r)
recordAAAA_identifier=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$zone_identifier/dns_records?name=$record_name&type=AAAA" -H "Authorization: Bearer $auth_key" -H "Content-Type: application/json" | jq '.result[0].id' -r)
#Update when A different
if [[ $ip != $recordA_ip ]]; then
    update=$(curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/$zone_identifier/dns_records/$recordA_identifier" -H "Authorization: Bearer $auth_key" -H "Content-Type: application/json" --data "{\"id\":\"$zone_identifier\",\"type\":\"A\",\"name\":\"$record_name\",\"content\":\"$ip\"}")
    if [[ $update == *"\"success\":false"* ]]; then
        message="v4 API UPDATE FAILED. DUMPING RESULTS:\n$update"
        log "$message"
        echo -e "$message"
        exit 1 
    else
        message="IPv4 changed to: $ip"
        log "$message"
    fi
fi
#Update when AAAA different
if [[ $ipSix != $recordAAAA_ip ]]; then
    updateSix=$(curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/$zone_identifier/dns_records/$recordAAAA_identifier" -H "Authorization: Bearer $auth_key" -H "Content-Type: application/json" --data "{\"id\":\"$zone_identifier\",\"type\":\"AAAA\",\"name\":\"$record_name\",\"content\":\"$ipSix\"}")
    if [[ $updateSix == *"\"success\":false"* ]]; then
        message="v6 API UPDATE FAILED. DUMPING RESULTS:\n$updateSix"
        log "$message"
        echo -e "$message"
        exit 1 
    else
        message="IPv6 changed to: $ipSix"
        log "$message"
    fi
fi
