param (
    [string]$ApiDomain = "",
    [string]$ApiID = ""
)

if ([string]::IsNullOrWhiteSpace($ApiDomain) -or [string]::IsNullOrWhiteSpace($ApiID)) {
    Write-Host "Error: Both ApiDomain and ApiID parameters must be provided."
    exit 1
}

$clientId = Read-Host -Prompt "Please paste the client_id of your Tesla application" -AsSecureString
$clientId = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto(
    [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($clientId)
)
$clientSecret = Read-Host -Prompt "Please paste the client_secret of your Tesla application" -AsSecureString
$clientSecret = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto(
    [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($clientSecret)
)

$arguments = @(
    "--request", "POST",
    "-s",
    "--header", "Content-Type: application/x-www-form-urlencoded",
    "--data-urlencode", "grant_type=client_credentials",
    "--data-urlencode", "client_id=$clientId",
    "--data-urlencode", "client_secret=$clientSecret",
    "--data-urlencode", "scope=openid vehicle_device_data vehicle_cmds vehicle_charging_cmds",
    "--data-urlencode", "audience=https://fleet-api.prd.na.vn.cloud.tesla.com",
    "https://fleet-auth.prd.vn.cloud.tesla.com/oauth2/v3/token"
)

$output = & "curl.exe" @arguments 2>&1  # Redirect stderr to stdout
Write-Host "1 - Create a new Tesla partner token..."

if (-not $output) {
    Write-Host "Error: empty response... The script seems to be blocked by Windows Try to run it in a PowerShell terminal: Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope CurrentUser"
    exit 1
}

$json = $output | ConvertFrom-Json
if (-not $json.access_token) {
    Write-Host "Error, your access token is empty. Here is the error detail:"
    Write-Host "$output"
    exit 1
}

$ACCESS_TOKEN = $json.access_token
$body = @{
    domain = "app-$ApiDomain.myteslamate.com"
} | ConvertTo-Json

$bodyString = $body | Out-String

$arguments = @(
    "--request", "POST",
    "-s",
    "--header", "Content-Type: application/json",
    "--header", "Authorization: Bearer $ACCESS_TOKEN",
    "--data", $bodyString,
    "https://fleet-api.prd.na.vn.cloud.tesla.com/api/1/partner_accounts"
)

$output = & "curl.exe" @arguments 2>&1  # Redirect stderr to stdout
Write-Host "2 - Register your own Tesla application in NA region..."
Write-Host "------------"
Write-Host "$output"

$json = $output | ConvertFrom-Json
if ($json.error) {
    Write-Host "Error registering your NA application. Here is the error detail:"
    Write-Host "$output"
    exit 1
}

$arguments = @(
    "--request", "POST",
    "-s",
    "--header", "Content-Type: application/json",
    "--header", "Authorization: Bearer $ACCESS_TOKEN",
    "--data", $bodyString,
    "https://fleet-api.prd.eu.vn.cloud.tesla.com/api/1/partner_accounts"
)

$output = & "curl.exe" @arguments 2>&1  # Redirect stderr to stdout
Write-Host "2 - Register your own Tesla application in EU region..."
Write-Host "------------"
Write-Host "$output"

$json = $output | ConvertFrom-Json
if ($json.error) {
    Write-Host "Error registering your EU application. Here is the error detail:"
    Write-Host "$output"
    exit 1
}

Write-Host "3 - Success! Click now on this link to log in and copy/paste the code needed to complete tokens generation:"
Write-Host ""
Write-Host ""
Write-Host "https://auth.tesla.com/oauth2/v3/authorize?client_id=$clientId&redirect_uri=https%3A%2F%2Fapp.myteslamate.com%2Fauth%2Ftesla%2F$ApiID%2Fcallback&scope=openid+offline_access+user_data+vehicle_device_data+vehicle_location+vehicle_cmds+vehicle_charging_cmds&response_type=code&prompt=login&state=$clientId"
Write-Host ""

$code = Read-Host -Prompt "Please paste the result code displayed " -AsSecureString
$code = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto(
    [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($code)
)

$arguments = @(
    "--request", "POST",
    "-s",
    "--header", "Content-Type: application/x-www-form-urlencoded",
    "--data-urlencode", "grant_type=authorization_code",
    "--data-urlencode", "client_id=$clientId",
    "--data-urlencode", "client_secret=$clientSecret",
    "--data-urlencode", "code=$code",
    "--data-urlencode", "audience=https://fleet-api.prd.$REGION.vn.cloud.tesla.com",
    "--data-urlencode", "redirect_uri=https://app.myteslamate.com/auth/tesla/$ApiID/callback",
    "https://fleet-auth.prd.vn.cloud.tesla.com/oauth2/v3/token"
)

$output = & "curl.exe" @arguments 2>&1  # Redirect stderr to stdout
Write-Host "--------------------------------------------"
Write-Host "4 - Your Tesla API access and secret tokens:"
Write-Host "--------------------------------------------"

$json = $output | ConvertFrom-Json
if ($null -eq $json -or $json.error) {
    Write-Host "Error generating token:"
    Write-Host "$output"
    exit 1
}

$ACCESS_TOKEN = $json.access_token
$REFRESH_TOKEN = $json.refresh_token
Write-Host "Access token: $ACCESS_TOKEN"
Write-Host "Refresh token: $REFRESH_TOKEN"
Write-Host "Refresh token:"
Write-Host "$json.refresh_token"
