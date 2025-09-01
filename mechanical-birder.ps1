
param(
  [string]$ApiToken = $env:EBIRD_API_TOKEN,
  [string]$Region   = $env:EBIRD_REGION_CODE,
  [int]   $BackDays = 7,
  [ValidateSet('simple','full')]
  [string]$Detail   = 'full',
  [int]   $MaxResults = 200,
  [string]$DiscordWebhook = $env:DISCORD_WEBHOOK_URL
)

# if you want you can save these in an environment var instead (technically more secure) 
# this only matters if you're running this on a system that other people have access to really

$ApiToken = 'YOUR EBIRD API KEY'
$Region   = 'YOUR COUNTY CODE FROM THE SETUP'
$DiscordWebhook = 'https://discord.com/api/webhooks/FULL WEBHOOK URL IN HERE'

$StateDir  = Join-Path $env:LOCALAPPDATA 'ebird-alerts'
$SeenFile  = Join-Path $StateDir ("{0}_seen.json" -f ($Region -replace '-', '_'))
$LogFile   = Join-Path $StateDir 'alerts.log'
New-Item -ItemType Directory -Force -Path $StateDir | Out-Null

function Write-Log($msg) {
  $ts = (Get-Date).ToString('s')
  Add-Content -Path $LogFile -Value "[${ts}] $msg"
}

if ([string]::IsNullOrWhiteSpace($ApiToken)) {
  Write-Error "Borb error: Set EBIRD_API_TOKEN env var or add it to the script plz"
  exit 1
}
if ([string]::IsNullOrWhiteSpace($Region)) {
  Write-Error "Borb error: EBIRD_REGION_CODE env var or add it to the script plz"
  exit 1
}


$seen = @()
if (Test-Path $SeenFile) {
  try { $seen = Get-Content $SeenFile | ConvertFrom-Json } catch {}
}
if (-not $seen) { $seen = @() }
$seenHash = [System.Collections.Generic.HashSet[string]]::new($seen)


$headers = @{ 'X-eBirdApiToken' = $ApiToken }
$baseUrl = "https://api.ebird.org/v2/data/obs/$Region/recent/"
$params  = @{
  back       = $BackDays
  detail     = $Detail
  maxResults = $MaxResults
}

$q = ($params.GetEnumerator() | ForEach-Object { "$($_.Key)=$($_.Value)" }) -join '&'
$uri = "$baseUrl`?$q"

try {
  $resp = Invoke-RestMethod -Uri $uri -Headers $headers -Method GET -TimeoutSec 30
} catch {
  Write-Log "Request failed: $($_.Exception.Message)"
  exit 2
}

function New-Key($o) {
  if ($o.obsId) { return "obs:$($o.obsId)" }
  return "$($o.subId)|$($o.speciesCode)|$($o.obsDt)"
}
function Format-Obs($o) {
  $parts = @()
  if ($o.comName) { $parts += $o.comName }
  if ($o.sciName) { $parts += "($($o.sciName))" }
  if ($o.howMany) { $parts += "• $($o.howMany)" }
  if ($o.locName) { $parts += "@ $($o.locName)" }
  if ($o.obsDt)   { $parts += "• $($o.obsDt)" }
  if ($o.userDisplayName) { $parts += "• by $($o.userDisplayName)" }
  ($parts -join ' ')
}

$new = @()
foreach ($o in $resp) {
  $k = New-Key $o
  if (-not $seenHash.Contains($k)) {
    $new += ,$o
    [void]$seenHash.Add($k)
  }
}

if ($new.Count -gt 0) {
  $new = $new | Sort-Object -Property obsDt
  foreach ($o in $new) {
    Write-Log ("NEW: " + (Format-Obs $o))
  }

# the notification (desktop):
  try {
    Import-Module BurntToast -ErrorAction SilentlyContinue | Out-Null
    $last = $new[-1]
    $title = "eBird: $($new.Count) new notable in $Region"
    $firstLine = Format-Obs $last
    New-BurntToastNotification -Text $title, ($firstLine + ($(if ($new.Count -gt 1) { "`n+{0} more…" -f ($new.Count-1) } else { "" })))
  } catch { Write-Log "Toast failed: $($_.Exception.Message)" }

    # the webhook (discord):

  if ($DiscordWebhook) {
    $summary = ($new | Select-Object -Last 5 | ForEach-Object { "- " + (Format-Obs $_) }) -join "`n"
    $payload = @{ content = "**$title**`n$firstLine" + ($(if ($new.Count -gt 1) { "`n+{0} more…" -f ($new.Count-1) } else { "" }) ) + "`n`n$summary" } | ConvertTo-Json
    try {
      Invoke-RestMethod -Uri $DiscordWebhook -Method POST -Body $payload -ContentType 'application/json'
    } catch { Write-Log "discord not configured correctly, this error may or may not be helpful: $($_.Exception.Message)" }
  }
} else {
  Write-Log "Nothing new found"
}

# this part is what saves the results:
($seenHash.ToArray() | ConvertTo-Json -Depth 1) | Set-Content -Path $SeenFile -Encoding UTF8
