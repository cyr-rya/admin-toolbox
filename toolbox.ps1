$ToolboxDir = "$PSScriptRoot\scripts"  # Local toolbox folder
$RemoteToolboxURL = "https://yourserver.com/toolbox.ps1"  # Remote update link

# Ensure Toolbox Folder Exists
if (-not (Test-Path $ToolboxDir)) { New-Item -Path $ToolboxDir -ItemType Directory -Force }

# Function: Update Toolbox
function Update-Toolbox {
    try {
        Write-Host "Checking for updates..." -ForegroundColor Cyan
        $remoteScript = Invoke-WebRequest -Uri $RemoteToolboxURL -UseBasicParsing
        $localScriptPath = "$PSScriptRoot\toolbox.ps1"

        if ((Get-FileHash -Path $localScriptPath -Algorithm SHA256).Hash -ne `
            (Get-FileHash -InputStream ($remoteScript.Content | Out-String | ConvertTo-SecureString -AsPlainText -Force) -Algorithm SHA256).Hash) {
            
            Write-Host "Updating toolbox..." -ForegroundColor Yellow
            $remoteScript.Content | Set-Content -Path $localScriptPath -Force
            Write-Host "Update complete. Restarting..." -ForegroundColor Green
            Start-Process "powershell.exe" -ArgumentList "-File `"$localScriptPath`"" -NoNewWindow
            exit
        } else {
            Write-Host "No updates found." -ForegroundColor Green
        }
    } catch {
        Write-Host "Failed to check for updates." -ForegroundColor Red
    }
}

# Function: List Available Scripts
function Get-AvailableScripts {
    Get-ChildItem -Path $ToolboxDir -Filter "*.ps1", "*.bat" | Select-Object Name, FullName
}

# Function: Run Selected Script
function Run-Script {
    $scripts = Get-AvailableScripts
    if (-not $scripts) {
        Write-Host "No scripts found in $ToolboxDir" -ForegroundColor Red
        return
    }

    Write-Host "`n===== Available Scripts =====" -ForegroundColor Cyan
    for ($i = 0; $i -lt $scripts.Count; $i++) {
        Write-Host "[$($i+1)] $($scripts[$i].Name)"
    }
    Write-Host "[X] Exit"

    $choice = Read-Host "Select a script number"
    if ($choice -eq "X") { return }

    $selectedScript = $scripts[$choice - 1].FullName
    if ($selectedScript -match "\.ps1$") {
        Write-Host "`nRunning PowerShell script: $selectedScript" -ForegroundColor Green
        Start-Process "powershell.exe" -ArgumentList "-ExecutionPolicy Bypass -File `"$selectedScript`"" -NoNewWindow -Wait
    } elseif ($selectedScript -match "\.bat$") {
        Write-Host "`nRunning Batch script: $selectedScript" -ForegroundColor Green
        Start-Process "cmd.exe" -ArgumentList "/c `"$selectedScript`"" -NoNewWindow -Wait
    } else {
        Write-Host "Invalid file type!" -ForegroundColor Red
    }
}

# Main Menu
while ($true) {
    Write-Host "`n===== SYSTEM TOOLBOX =====" -ForegroundColor Cyan
    Write-Host "[1] Run a script"
    Write-Host "[2] Check for updates"
    Write-Host "[X] Exit"

    $input = Read-Host "Choose an option"
    switch ($input) {
        "1" { Run-Script }
        "2" { Update-Toolbox }
        "X" { exit }
        default { Write-Host "Invalid selection, try again." -ForegroundColor Red }
    }
}
