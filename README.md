## To get this working you will need:

- powershell
- an ebird api key
- county code (see below)
- BurntToast (notifications)
- a discord server with a configured webhook available
- the ability to set a task scheduler task


## SETUP

Clone repo to a directory then complete below:

## if you want desktop notifications:

- Run powershell (ctrl+r then type `powershell` then hit enter, or alternatively whatever your favourite way to run powershell is)

```powershell
Install-Module BurntToast -Scope CurrentUser -Force
```

## getting your county code:

- List all Texas counties and grab yours:

```powershell
$hdr = @{ 'X-eBirdApiToken' = 'YOUR_API_KEY' }
Invoke-RestMethod -Uri 'https://api.ebird.org/v2/ref/region/list/subnational2/US-TX' -Headers $hdr |
  Select-Object code, name | Format-Table -Auto
```

- Keep this county code to add to the script after.

## optional env var config 
### (by default you just can paste these values directly into the script instead of doing this part but technically this would be ideal)

if you want to, you can put the API key directly in the script, or you can set them in an env var, up to you.

```powershell
[Environment]::SetEnvironmentVariable('EBIRD_API_TOKEN','YOUR_API_KEY_HERE','User')
[Environment]::SetEnvironmentVariable('EBIRD_REGION_CODE','COUNTY CODE','User')
[Environment]::SetEnvironmentVariable('DISCORD_WEBHOOK_URL','FULL WEBHOOK URL HERE','User')
```

## Test: 

```powershell
powershell -ExecutionPolicy Bypass -File "C:\path_to_mechanical-birder.ps1"
```

## Setup for the trigger (every 30 mins)
### can be done via task scheduler OR via terminal. 
### You do not need to do both

## Terminal version:

I am not on windows so i can't test this but copilot says it'd be:

```powershell
schtasks /Create /TN "eBird Alerts" /SC MINUTE /MO 30 ^
  /TR "powershell -NoProfile -ExecutionPolicy Bypass -File C:\path_to_mechanical-birder.ps1" ^
  /RL LIMITED
```

## task scheduler version:

Open task scheduler and 'Create Task'

General:

Name: eBird Alerts

optional: `“Run only when user is logged on”` 
- if you are using toast messages you can select this to prevent a lot of notifications upon unlocking your pc, you may not care tho

Triggers:

Select new and then `Begin the task: On a schedule → Daily`

`Repeat task every 30 minutes` for `Indefinitely`

Actions:

Select new and then `Program/script: powershell`

arguments:

`-NoProfile -ExecutionPolicy Bypass -File "C:\path_to_mechanical-birder.ps1"`


Start in: path of the directory 

Conditions: uncheck “Start the task only if the computer is on AC power” if your pc is a laptop and you want it to run without wall power

Then hit ok and make sure it's saved. Then you pretty much wait 30 mins and it should run the first time (the first automatic time anyways)