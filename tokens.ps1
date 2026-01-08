param (
    [Parameter(Mandatory=$true)]
    [string]$ApiDomain
)

# Validate domain
if ([string]::IsNullOrWhiteSpace($ApiDomain)) {
    Write-Host "Error: ApiDomain parameter must be provided."
    exit 1
}

# Get Tesla app credentials
$clientId = Read-Host -Prompt "Please paste the client_id of your Tesla application"
$clientSecret = Read-Host -Prompt "Please paste the client_secret of your Tesla application"

Write-Host "1 - Creating new Tesla partner token..."

# First token request for partner registration
$arguments = @(
    "--request", "POST",
    "-s",
    "--header", "Content-Type: application/x-www-form-urlencoded",
    "--data-urlencode", "grant_type=client_credentials",
    "--data-urlencode", "client_id=$clientId",
    "--data-urlencode", "client_secret=$clientSecret",
    "--data-urlencode", "scope=openid vehicle_device_data vehicle_location vehicle_cmds vehicle_charging_cmds energy_device_data vehicle_specs energy_cmds",
    "--data-urlencode", "audience=https://fleet-api.prd.na.vn.cloud.tesla.com",
    "https://fleet-auth.prd.vn.cloud.tesla.com/oauth2/v3/token"
)

$output = & "curl.exe" @arguments 2>&1
if (-not $output) {
    Write-Host "Error: empty response. Please ensure curl.exe is available."
    exit 1
}

$json = $output | ConvertFrom-Json
if (-not $json.access_token) {
    Write-Host "Error getting access token. Details:"
    Write-Host "$output"
    exit 1
}

$ACCESS_TOKEN = $json.access_token

# Prepare the body with proper JSON escaping
$bodyData = @{
    domain = "app-$ApiDomain.myteslamate.com"
}
$bodyJson = $bodyData | ConvertTo-Json -Compress

# Register in NA region
Write-Host "2 - Registering application in NA region..."
$arguments = @(
    "--request", "POST",
    "-s",
    "--header", "Content-Type: application/json",
    "--header", "Authorization: Bearer $ACCESS_TOKEN",
    "--data", "`"$($bodyJson.Replace('"','\"'))`"",
    "https://fleet-api.prd.na.vn.cloud.tesla.com/api/1/partner_accounts"
)

$output = & "curl.exe" @arguments 2>&1
Write-Host "Response: $output"

$json = $output | ConvertFrom-Json
if ($json.error) {
    Write-Host "Error registering in NA region. Details:"
    Write-Host "$output"
    exit 1
}

# Register in EU region
Write-Host "2 - Registering application in EU region..."
$arguments = @(
    "--request", "POST",
    "-s",
    "--header", "Content-Type: application/json",
    "--header", "Authorization: Bearer $ACCESS_TOKEN",
    "--data", "`"$($bodyJson.Replace('"','\"'))`"",
    "https://fleet-api.prd.eu.vn.cloud.tesla.com/api/1/partner_accounts"
)

$output = & "curl.exe" @arguments 2>&1
Write-Host "Response: $output"

$json = $output | ConvertFrom-Json
if ($json.error) {
    Write-Host "Error registering in EU region. Details:"
    Write-Host "$output"
    exit 1
}

# Generate auth URL
Write-Host "`n3 - Please open this URL in your browser to authorize:"
Write-Host "https://fleet-auth.prd.vn.cloud.tesla.com/oauth2/v3/authorize?client_id=$clientId&redirect_uri=https%3A%2F%2Fapp.myteslamate.com%2Fauth%2Ftesla%2Fuser%2Fcallback&scope=openid+offline_access+user_data+vehicle_device_data+vehicle_location+vehicle_cmds+vehicle_charging_cmds+energy_device_data+vehicle_specs+energy_cmds&response_type=code&prompt=login&state=$clientId"
Write-Host ""

$code = Read-Host -Prompt "Please paste the authorization code from the URL"

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
    "https://fleet-auth.prd.vn.cloud.tesla.com/oauth2/v3/token"
)

$output = & "curl.exe" @arguments 2>&1
Write-Host "`n--------------------------------------------"
Write-Host "4 - Your Tesla API tokens:"
Write-Host "--------------------------------------------"

$json = $output | ConvertFrom-Json
if ($null -eq $json -or $json.error) {
    Write-Host "Error generating final tokens:"
    Write-Host "$output"
    exit 1
}

Write-Host "Access token: $($json.access_token)"
Write-Host "Refresh token: $($json.refresh_token)"