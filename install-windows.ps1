# PCloud klienti - Windows. PowerShell'ni "Administrator" sifatida ishga tushiring.
# Faqat Oracle serveri:
#   .\install-windows.ps1 -Url "https://mening-bulutim.duckdns.org"
# Bepul hisoblarni ham birlashtirish (avval add-free-accounts.md bo'yicha ulang):
#   .\install-windows.ps1 -Url "https://mening-bulutim.duckdns.org" -Extras "mega,gdrive,pcl"
# Oracle 200 GB to'lganda yangi fayllar boshqa hisoblarga tushishi uchun -OracleFull qo'shing.
param(
  [Parameter(Mandatory=$true)][string]$Url,
  [string]$User = "admin",
  [string]$Drive = "P:",
  [string]$CacheGB = "10",
  [string]$Extras = "",
  [switch]$OracleFull
)

$ErrorActionPreference = "Stop"

Write-Host "1/4 rclone va WinFsp o'rnatilmoqda..."
winget install --id Rclone.Rclone -e --accept-source-agreements --accept-package-agreements
winget install --id WinFsp.WinFsp -e --accept-source-agreements --accept-package-agreements

$rclone = (Get-Command rclone -ErrorAction SilentlyContinue).Source
if (-not $rclone) {
  $rclone = Get-ChildItem "$env:LOCALAPPDATA\Microsoft\WinGet\Packages" -Recurse -Filter rclone.exe | Select-Object -First 1 -ExpandProperty FullName
}
if (-not $rclone) { throw "rclone topilmadi. Terminalni qayta oching va qayta urinib ko'ring." }

Write-Host "2/4 Parolni kiriting (ekranda ko'rinmaydi)..."
$sec = Read-Host -AsSecureString "Bulut paroli"
$plain = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($sec))
$obscured = & $rclone obscure $plain
& $rclone config create mycloud webdav url $Url vendor other user $User pass $obscured | Out-Null

$remote = "mycloud:"
if ($Extras.Trim()) {
  $have = & $rclone listremotes
  $first = if ($OracleFull) { "mycloud::nc" } else { "mycloud:" }
  $ups = @($first)
  foreach ($e in ($Extras -split "," | ForEach-Object { $_.Trim() } | Where-Object { $_ })) {
    if ($have -contains "${e}:") { $ups += "${e}:" }
    else { Write-Warning "'$e' nomli ulanish topilmadi, o'tkazib yuborildi (add-free-accounts.md ga qarang)" }
  }
  if ($ups.Count -gt 1) {
    & $rclone config create cloudall union upstreams ($ups -join " ") create_policy ff action_policy epall search_policy ff | Out-Null
    $remote = "cloudall:"
    Write-Host "Birlashtirilgan hisoblar: $($ups -join ', ')"
  }
}

Write-Host "3/4 Avtomatik ishga tushirish sozlanmoqda..."
$mountArgs = "mount $remote $Drive --vfs-cache-mode full --vfs-cache-max-size ${CacheGB}G --vfs-cache-max-age 24h --vfs-read-chunk-size 64M --dir-cache-time 10m --no-console"
$action = New-ScheduledTaskAction -Execute $rclone -Argument $mountArgs
$trigger = New-ScheduledTaskTrigger -AtLogOn
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -RestartCount 99 -RestartInterval (New-TimeSpan -Minutes 1) -ExecutionTimeLimit ([TimeSpan]::Zero)
Register-ScheduledTask -TaskName "PCloud-Mount" -Action $action -Trigger $trigger -Settings $settings -Force | Out-Null

Write-Host "4/4 Hozir ishga tushirilmoqda..."
Start-ScheduledTask -TaskName "PCloud-Mount"
Start-Sleep -Seconds 5
if (Test-Path "$Drive\") { Write-Host "Tayyor! $Drive disk ulandi." } else { Write-Host "Disk hali ko'rinmadi. Bir necha soniya kuting yoki kompyuterni qayta ishga tushiring." }
