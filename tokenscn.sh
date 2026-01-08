#!/bin/bash

# Get input parameter
API_DOMAIN="$1"

if [ -z "$API_DOMAIN" ]; then
    echo -e "\033[1;31m错误：需要 API_DOMAIN 参数。\033[0m"
    echo "用法：$0 <API_DOMAIN>"
    exit 1
fi

read -p "请粘贴您的特斯拉应用程序的 client_id：" clientId </dev/tty
echo
read -p "请粘贴您的特斯拉应用程序的 client_secret：" clientSecret </dev/tty
echo

echo -e "\033[1;34m1 - 登录到您的特斯拉合作伙伴令牌...\033[0m"

response=$(curl --request POST -s \
    --header "Content-Type: application/x-www-form-urlencoded" \
    --data-urlencode "grant_type=client_credentials" \
    --data-urlencode "client_id=$clientId" \
    --data-urlencode "client_secret=$clientSecret" \
    --data-urlencode "scope=openid vehicle_device_data vehicle_location vehicle_cmds vehicle_charging_cmds energy_device_data energy_cmds" \
    --data-urlencode "audience=https://fleet-api.prd.cn.vn.cloud.tesla.cn" \
    "https://auth.tesla.cn/oauth2/v3/token")

token=$(echo "$response" | sed -n 's/.*"access_token":"\([^"]*\)".*/\1/p')

if [ -z "$token" ] || [ "$token" = "null" ]; then
    echo "\033[1;31m错误，您的访问令牌为空。错误详细信息：\033[0m"
    echo "$response"
    exit 1
fi

echo -e "\033[1;34m2 - 在中国区域注册您的特斯拉应用程序...\033[0m"

response=$(curl --request POST -s \
    --header "Content-Type: application/json" \
    --header "Authorization: Bearer $token" \
    --data "{ \"domain\": \"app-$API_DOMAIN.myteslamate.com\" }" \
    "https://fleet-api.prd.cn.vn.cloud.tesla.cn/api/1/partner_accounts")

error=$(echo "$response" | sed -n 's/.*"error":"\([^"]*\)".*/\1/p')

if [ ! -z "$error" ] && [ "$error" != "null" ]; then
    echo -e "\033[1;31m注册您的中国应用程序时出错。错误详细信息：\033[0m"
    echo "$response"
    exit 1
fi

echo -e "\033[1;34m3 - 最后一步，现在点击此链接登录并复制/粘贴完成令牌生成所需的代码：\033[0m"
echo ""
echo -e "\033[1;32mhttps://auth.tesla.cn/oauth2/v3/authorize?client_id=$clientId&redirect_uri=https%3A%2F%2Fapp.myteslamate.com%2Fauth%2Ftesla%2Fuser%2Fcallback&scope=openid+offline_access+user_data+vehicle_device_data+vehicle_location+vehicle_cmds+vehicle_charging_cmds+energy_device_data+energy_cmds&response_type=code&prompt=login&state=$clientId\033[0m"
echo ""
read -p "请粘贴特斯拉登录后 MyTeslamate 显示的代码：" code </dev/tty
echo

response=$(curl -s -X POST \
    -H "Content-Type: application/x-www-form-urlencoded" \
    --data-urlencode "grant_type=authorization_code" \
    --data-urlencode "client_id=$clientId" \
    --data-urlencode "client_secret=$clientSecret" \
    --data-urlencode "code=$code" \
    --data-urlencode "redirect_uri=https://app.myteslamate.com/auth/tesla/user/callback" \
    "https://auth.tesla.cn/oauth2/v3/token")

error=$(echo "$response" | grep "error")
if [ ! -z "$error" ] && [ "$error" != "null" ]; then
    echo -e "\033[1;31m登录到您的应用程序时出错。错误详细信息：\033[0m"
    echo "$error"
    exit 1
fi

echo -e "\033[1;34m4 - 您的特斯拉 API 访问和刷新令牌：\033[0m"
access_token=$(echo "$response" | sed -n 's/.*"access_token":"\([^"]*\)".*/\1/p')
refresh_token=$(echo "$response" | sed -n 's/.*"refresh_token":"\([^"]*\)".*/\1/p')
echo -e "\033[1;32m访问令牌：\033[0m $access_token"
echo -e "\033[1;32m刷新令牌：\033[0m $refresh_token"
