To get this working you will need:

county code

1. run powershell (windows terminal)

This is what sends notifications so install it:

```powershell
Install-Module BurntToast -Scope CurrentUser -Force
```

List all Texas counties and grab yours:

```powershell
$hdr = @{ 'X-eBirdApiToken' = 'YOUR_API_KEY' }
Invoke-RestMethod -Uri 'https://api.ebird.org/v2/ref/region/list/subnational2/US-TX' -Headers $hdr |
  Select-Object code, name | Format-Table -Auto
```

Keep this county code to add to the script after.

THEN

if you want to, you can put the API key directly in the script, or you can set them in an env var, up to you.

Test: 

```powershell
powershell -ExecutionPolicy Bypass -File "C:\ebird\ebird-alerts.ps1"
```

Setup the trigger that runs this thing every 30 mins can be done via task scheduler OR via terminal. 

I am not on windows so i can't test this but copilot says it'd be:

```powershell
schtasks /Create /TN "eBird Alerts" /SC MINUTE /MO 30 ^
  /TR "powershell -NoProfile -ExecutionPolicy Bypass -File path_to_mechanical-birder.ps1" ^
  /RL LIMITED
```

For task scheduler:

Open task scheduler and 'Create Task'

General:

Name: eBird Alerts

“Run only when user is logged on” (if you are using toast messages you can select this to prevent a lot of notifications upon unlocking your pc, you may not care tho)

Triggers:

Select new and then `Begin the task: On a schedule → Daily`

`Repeat task every 30 minutes` for `Indefinitely`

Actions:

Select new and then `Program/script: powershell`

for arguments:

`-NoProfile -ExecutionPolicy Bypass -File "path_to_mechanical-birder.ps1"`


Start in: path of the directory 

Conditions: uncheck “Start the task only if the computer is on AC power” if your pc is a laptop and you want it to run without wall power

Then hit ok and make sure it's saved.