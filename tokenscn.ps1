param (
    [Parameter(Mandatory=$true)]
    [string]$ApiDomain
)

# Validate domain
if ([string]::IsNullOrWhiteSpace($ApiDomain)) {
    Write-Host "错误：必须提供 ApiDomain 参数。"
    exit 1
}

# Get Tesla app credentials
$clientId = Read-Host -Prompt "请粘贴您的特斯拉应用程序的 client_id"
$clientSecret = Read-Host -Prompt "请粘贴您的特斯拉应用程序的 client_secret"

Write-Host "1 - 创建新的特斯拉合作伙伴令牌..."

# First token request for partner registration
$arguments = @(
    "--request", "POST",
    "-s",
    "--header", "Content-Type: application/x-www-form-urlencoded",
    "--data-urlencode", "grant_type=client_credentials",
    "--data-urlencode", "client_id=$clientId",
    "--data-urlencode", "client_secret=$clientSecret",
    "--data-urlencode", "scope=openid vehicle_device_data vehicle_location vehicle_cmds vehicle_charging_cmds energy_device_data energy_cmds",
    "--data-urlencode", "audience=https://fleet-api.prd.cn.vn.cloud.tesla.cn",
    "https://auth.tesla.cn/oauth2/v3/token"
)

$output = & "curl.exe" @arguments 2>&1
if (-not $output) {
    Write-Host "错误：响应为空。请确保 curl.exe 可用。"
    exit 1
}

$json = $output | ConvertFrom-Json
if (-not $json.access_token) {
    Write-Host "获取访问令牌时出错。详细信息："
    Write-Host "$output"
    exit 1
}

$ACCESS_TOKEN = $json.access_token

# Prepare the body with proper JSON escaping
$bodyData = @{
    domain = "app-$ApiDomain.myteslamate.com"
}
$bodyJson = $bodyData | ConvertTo-Json -Compress

# Register in CN region
Write-Host "2 - 在中国区域注册应用程序..."
$arguments = @(
    "--request", "POST",
    "-s",
    "--header", "Content-Type: application/json",
    "--header", "Authorization: Bearer $ACCESS_TOKEN",
    "--data", "`"$($bodyJson.Replace('"','\"'))`"",
    "https://fleet-api.prd.cn.vn.cloud.tesla.cn/api/1/partner_accounts"
)

$output = & "curl.exe" @arguments 2>&1
Write-Host "Response: $output"

$json = $output | ConvertFrom-Json
if ($json.error) {
    Write-Host "在中国区域注册时出错。详细信息："
    Write-Host "$output"
    exit 1
}

# Generate auth URL
Write-Host "`n3 - 请在浏览器中打开此链接进行授权："
Write-Host "https://fleet-auth.prd.vn.cloud.tesla.com/oauth2/v3/authorize?client_id=$clientId&redirect_uri=https%3A%2F%2Fapp.myteslamate.com%2Fauth%2Ftesla%2Fuser%2Fcallback&scope=openid+offline_access+user_data+vehicle_device_data+vehicle_location+vehicle_cmds+vehicle_charging_cmds+energy_device_data+energy_cmds&response_type=code&prompt=login&state=$clientId"
Write-Host ""

$code = Read-Host -Prompt "请粘贴特斯拉登录后 MyTeslamate 显示的授权代码"

# Final token exchange
$arguments = @(
    "--request", "POST",
    "-s",
    "--header", "Content-Type: application/x-www-form-urlencoded",
    "--data-urlencode", "grant_type=authorization_code",
    "--data-urlencode", "client_id=$clientId",
    "--data-urlencode", "client_secret=$clientSecret",
    "--data-urlencode", "code=$code",
    "--data-urlencode", "redirect_uri=https://app.myteslamate.com/auth/tesla/user/callback",
    "https://auth.tesla.cn/oauth2/v3/token"
)

$output = & "curl.exe" @arguments 2>&1
Write-Host "`n--------------------------------------------"
Write-Host "4 - 您的特斯拉 API 令牌："
Write-Host "--------------------------------------------"

$json = $output | ConvertFrom-Json
if ($null -eq $json -or $json.error) {
    Write-Host "生成最终令牌时出错："
    Write-Host "$output"
    exit 1
}

Write-Host "访问令牌：$($json.access_token)"
Write-Host "刷新令牌：$($json.refresh_token)"