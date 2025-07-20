#!/bin/bash

# Get input parameter
API_DOMAIN="$1"

if [ -z "$API_DOMAIN" ]; then
    echo -e "\033[1;31mError: API_DOMAIN parameter is required.\033[0m"
    echo "Usage: $0 <API_DOMAIN>"
    exit 1
fi

read -p "Please paste the client_id of your Tesla application: " clientId </dev/tty
echo
read -p "Please paste the client_secret of your Tesla application: " clientSecret </dev/tty
echo

echo -e "\033[1;34m1 - Log in to your Tesla partner token...\033[0m"

response=$(curl --request POST -s \
    --header "Content-Type: application/x-www-form-urlencoded" \
    --data-urlencode "grant_type=client_credentials" \
    --data-urlencode "client_id=$clientId" \
    --data-urlencode "client_secret=$clientSecret" \
    --data-urlencode "scope=openid vehicle_device_data vehicle_location vehicle_cmds vehicle_charging_cmds energy_device_data energy_cmds" \
    --data-urlencode "audience=https://fleet-api.prd.na.vn.cloud.tesla.com" \
    "https://fleet-auth.prd.vn.cloud.tesla.com/oauth2/v3/token")

token=$(echo "$response" | sed -n 's/.*"access_token":"\([^"]*\)".*/\1/p')

if [ -z "$token" ] || [ "$token" = "null" ]; then
    echo "\033[1;31mError, your access token is empty. Here is the error detail:\033[0m"
    echo "$response"
    exit 1
fi

echo -e "\033[1;34m2 - Register your own Tesla application in NA region...\033[0m"

response=$(curl --request POST -s \
    --header "Content-Type: application/json" \
    --header "Authorization: Bearer $token" \
    --data "{ \"domain\": \"app-$API_DOMAIN.myteslamate.com\" }" \
    "https://fleet-api.prd.na.vn.cloud.tesla.com/api/1/partner_accounts")

error=$(echo "$response" | sed -n 's/.*"error":"\([^"]*\)".*/\1/p')

if [ ! -z "$error" ] && [ "$error" != "null" ]; then
    echo -e "\033[1;31mError registering your NA application. Here is the error detail:\033[0m"
    echo "$response"
    exit 1
fi
echo -e "\033[1;34m2 - Register your own Tesla application in EU region...\033[0m"

response=$(curl --request POST -s \
    --header "Content-Type: application/json" \
    --header "Authorization: Bearer $token" \
    --data "{ \"domain\": \"app-$API_DOMAIN.myteslamate.com\" }" \
    "https://fleet-api.prd.eu.vn.cloud.tesla.com/api/1/partner_accounts")

error=$(echo "$response" | sed -n 's/.*"error":"\([^"]*\)".*/\1/p')

if [ ! -z "$error" ] && [ "$error" != "null" ]; then
    echo -e "\033[1;31mError registering your EU application. Here is the error detail:\033[0m"
    echo "$response"
    exit 1
fi

echo -e "\033[1;34m3 - Last step, click now on this link to log in and copy/paste the code needed to complete tokens generation:\033[0m"
echo ""
echo -e "\033[1;32mhttps://auth.tesla.com/oauth2/v3/authorize?client_id=$clientId&redirect_uri=https%3A%2F%2Fapp.myteslamate.com%2Fauth%2Ftesla%2Fuser%2Fcallback&scope=openid+offline_access+user_data+vehicle_device_data+vehicle_location+vehicle_cmds+vehicle_charging_cmds+energy_device_data+energy_cmds&response_type=code&prompt=login&state=$clientId\033[0m"
echo ""
read -p "Please paste the code displayed on MyTeslamate after Tesla login: " code </dev/tty
echo

response=$(curl -s -X POST \
    -H "Content-Type: application/x-www-form-urlencoded" \
    --data-urlencode "grant_type=authorization_code" \
    --data-urlencode "client_id=$clientId" \
    --data-urlencode "client_secret=$clientSecret" \
    --data-urlencode "code=$code" \
    --data-urlencode "redirect_uri=https://app.myteslamate.com/auth/tesla/user/callback" \
    "https://fleet-auth.prd.vn.cloud.tesla.com/oauth2/v3/token")

error=$(echo "$response" | grep "error")
if [ ! -z "$error" ] && [ "$error" != "null" ]; then
    echo -e "\033[1;31mError logging into your application. Here is the error detail:\033[0m"
    echo "$error"
    exit 1
fi

echo -e "\033[1;34m4 - Your Tesla API access and secret tokens:\033[0m"
access_token=$(echo "$response" | sed -n 's/.*"access_token":"\([^"]*\)".*/\1/p')
refresh_token=$(echo "$response" | sed -n 's/.*"refresh_token":"\([^"]*\)".*/\1/p')
echo -e "\033[1;32maccess_token:\033[0m $access_token"
echo -e "\033[1;32mrefresh_token:\033[0m $refresh_token"
