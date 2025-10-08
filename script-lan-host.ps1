# Set the subnet you want to scan
$subnet = "192.168.5"

# Output files
$activeFile = "$PSScriptRoot\active-ips.txt"
$unusedFile = "$PSScriptRoot\unused-ips.txt"

# Clear previous results
Clear-Content -Path $activeFile -ErrorAction SilentlyContinue
Clear-Content -Path $unusedFile -ErrorAction SilentlyContinue

Write-Host "🔍 Scanning subnet $subnet.0/24..." -ForegroundColor Cyan

# Scan IP range 1 E54
1..254 | ForEach-Object {
    $ip = "$subnet.$_"
    $ping = Test-Connection -ComputerName $ip -Count 1 -Quiet
    if ($ping) {
        Write-Host "$ip is ACTIVE" -ForegroundColor Green
        Add-Content -Path $activeFile -Value $ip
    }
    else {
        Write-Host "$ip is UNUSED" -ForegroundColor DarkGray
        Add-Content -Path $unusedFile -Value $ip
    }
}

Write-Host "`n✁EScan complete!" -ForegroundColor Cyan
Write-Host "🟢 Active IPs saved to: $activeFile"
Write-Host "⚪ Unused IPs saved to: $unusedFile"
