# Offload skriptini har kuni avtomatik ishga tushiradi (Windows). Avval sinov rejimida ishlatib ko'ring!
# Ishlatish: .\install-offload-task.ps1 -Folders "C:\Users\Men\Videos","C:\Users\Men\Downloads"
param(
  [Parameter(Mandatory=$true)][string[]]$Folders,
  [string]$Drive = "P:\",
  [int]$Days = 90,
  [int]$MinMB = 20
)
$script = Join-Path $PSScriptRoot "offload.py"
$folderArgs = ($Folders | ForEach-Object { '"' + $_ + '"' }) -join " "
$arg = "`"$script`" --mount `"$Drive`" --folders $folderArgs --days $Days --min-mb $MinMB --apply"
$action = New-ScheduledTaskAction -Execute "python" -Argument $arg
$trigger = New-ScheduledTaskTrigger -Daily -At 3am
Register-ScheduledTask -TaskName "PCloud-Offload" -Action $action -Trigger $trigger -Force | Out-Null
Write-Host "Har kuni soat 03:00 da avtomatik tozalash yoqildi."
