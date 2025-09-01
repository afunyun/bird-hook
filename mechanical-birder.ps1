# a set of configurable variables. If you want to change any of these values, you can do so here,
# also if you uncomment the $ApiToken, $Region, and $DiscordWebhook lines, you can use environment variables for configuration instead which is
# more secure but i mean it's a birding API so

param(
#  [string]$ApiToken = $env:EBIRD_API_TOKEN,
#  [string]$Region   = $env:EBIRD_REGION_CODE,
  [int]   $BackDays = 7,
  [ValidateSet('simple','full')]
  [string]$Detail   = 'full',
  [int]   $MaxResults = 200,
#  [string]$DiscordWebhook = $env:DISCORD_WEBHOOK_URL
)

# these set the API token, region, and webhook so the later bits can use it, assuming you uncomment the lines above in the params.
# automatically will check if they're set first and just use that if they are, that's what the conditional (eg if (-not $ApiToken))
# are there for. Otherwise it'll just overwrite them which is pointless

if (-not $ApiToken) {
  $ApiToken = 'YOUR EBIRD API KEY'
}
if (-not $Region) {
  $Region = 'YOUR COUNTY CODE FROM THE SETUP'
}

if (-not $DiscordWebhook) {
  $DiscordWebhook = 'https://discord.com/api/webhooks/FULL WEBHOOK URL IN HERE'
}

# this is just setting up the save location in appdata for the alerts so it knows what was saved before. 
# you can also go here to see all the previous sightings that were saved.

$StateDir  = Join-Path $env:LOCALAPPDATA 'ebird-alerts'
$SeenFile  = Join-Path $StateDir ("{0}_seen.json" -f ($Region -replace '-', '_'))
$LogFile   = Join-Path $StateDir 'alerts.log'
New-Item -ItemType Directory -Force -Path $StateDir | Out-Null

# adds the current timestamp to the log file

function Write-Log($msg) {
  $ts = (Get-Date).ToString('s')
  Add-Content -Path $LogFile -Value "[${ts}] $msg"
}

# checks that we actually have the token and region set since there's no point sending a request without those

if ([string]::IsNullOrWhiteSpace($ApiToken)) {
  Write-Error "Borb error: Set EBIRD_API_TOKEN env var or add it to the script plz"
  exit 1
}
if ([string]::IsNullOrWhiteSpace($Region)) {
  Write-Error "Borb error: EBIRD_REGION_CODE env var or add it to the script plz"
  exit 1
}

# checks if there's a seen file already or not, if there is it loads the seen data from the file to compare later.

$seen = @()
if (Test-Path $SeenFile) {
  try { $seen = Get-Content $SeenFile | ConvertFrom-Json } catch { Write-Log "seen file is fubar: $($_.Exception.Message)" }
}
if (-not $seen) { $seen = @() }

# this makes sure there isn't a timebomb in the $seen variable and turns everything into a string.

$seen = @($seen | ForEach-Object { if ($_ -is [string]) { $_ } else { $_.ToString() } })
$seenHash = [System.Collections.Generic.HashSet[string]]::new($seen)

# set headers for the request to the API, these are what authenticate your system to the API

$headers = @{ 'X-eBirdApiToken' = $ApiToken }
$baseUrl = "https://api.ebird.org/v2/data/obs/$Region/recent/"
$params  = @{
  back       = $BackDays
  detail     = $Detail
  maxResults = $MaxResults
}

$q = ($params.GetEnumerator() | ForEach-Object { "$($_.Key)=$($_.Value)" }) -join '&'
$uri = "$baseUrl`?$q"

# checks that the REST API is accessible (eBird API is a REST API)

try {
  $resp = Invoke-RestMethod -Uri $uri -Headers $headers -Method GET -TimeoutSec 30
} catch {
  Write-Log "Request failed: $($_.Exception.Message)"
  exit 2
}

# adds a new key for each observation

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

# this is a loop that formats the keys from right above this

$new = @()
foreach ($o in $resp) {
  $k = New-Key $o
  if (-not $seenHash.Contains($k)) {
    $new += ,$o
    [void]$seenHash.Add($k)
  }
}

# logs new observations to the log file in your appdata and then sends the webhook & notification

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
    $payload = @{
      content = "**$title**`n$firstLine" + ($(if ($new.Count -gt 1) { "`n+{0} more…" -f ($new.Count-1) } else { "" }) ) + "`n`n$summary"
    }
    $payloadJson = $payload | ConvertTo-Json
    try {
      Invoke-RestMethod -Uri $DiscordWebhook -Method POST -Body $payloadJson -ContentType 'application/json'
    } catch { Write-Log "discord not configured correctly, this error may or may not be helpful: $($_.Exception.Message)" }
  }
} else {
  Write-Log "Nothing new found"
}

# this part is what saves the results (first it checks if the file is even there then it merges existing seen data with new entries):

$existingSeen = @()
if (Test-Path $SeenFile) {
  try { $existingSeen = Get-Content $SeenFile | ConvertFrom-Json } catch { $existingSeen = @() }
}
$allSeen = [System.Collections.Generic.HashSet[string]]::new($existingSeen + $seenHash.ToArray())
($allSeen.ToArray() | ConvertTo-Json -Depth 3) | Set-Content -Path $SeenFile -Encoding UTF8

# i had copilot review this since i can't test and changed some stuff on suggestion so if it doesn't work just blame copilot 4Head