$ToolboxDir = "$PSScriptRoot\scripts"
$Categories = @("Serveur", "Ordinateur", "Déploiement")
$RemoteToolboxURL = "https://yourserver.com/toolbox.ps1"  # Remote update link

# Ensure required folders exist
foreach ($category in $Categories) {
    $categoryPath = "$ToolboxDir\$category"
    if (-not (Test-Path $categoryPath)) {
        New-Item -Path $categoryPath -ItemType Directory -Force
    }
}

# Function: Update Toolbox
function Update-Toolbox {
    try {
        Write-Host "🔄 Vérification des mises à jour..." -ForegroundColor Cyan
        $remoteScript = Invoke-WebRequest -Uri $RemoteToolboxURL -UseBasicParsing
        $localScriptPath = "$PSScriptRoot\toolbox.ps1"

        if ((Get-FileHash -Path $localScriptPath -Algorithm SHA256).Hash -ne `
            (Get-FileHash -InputStream ($remoteScript.Content | Out-String | ConvertTo-SecureString -AsPlainText -Force) -Algorithm SHA256).Hash) {
            
            Write-Host "🚀 Mise à jour du toolbox..." -ForegroundColor Yellow
            $remoteScript.Content | Set-Content -Path $localScriptPath -Force
            Write-Host "✅ Mise à jour terminée. Redémarrage..." -ForegroundColor Green
            Start-Process "powershell.exe" -ArgumentList "-File `"$localScriptPath`"" -NoNewWindow
            exit
        } else {
            Write-Host "✅ Aucune mise à jour disponible." -ForegroundColor Green
        }
    } catch {
        Write-Host "❌ Impossible de vérifier les mises à jour." -ForegroundColor Red
    }
}

# Function: List Available Scripts in a Category
function Get-AvailableScripts($Category) {
    Get-ChildItem -Path "$ToolboxDir\$Category" -Filter "*.ps1", "*.bat" | Select-Object Name, FullName
}

# Function: Run Selected Script
function Run-Script($Category) {
    $scripts = Get-AvailableScripts -Category $Category
    if (-not $scripts) {
        Write-Host "❌ Aucun script trouvé dans '$Category'" -ForegroundColor Red
        return
    }

    Write-Host "`n📜 Scripts disponibles dans '$Category' :" -ForegroundColor Cyan
    for ($i = 0; $i -lt $scripts.Count; $i++) {
        Write-Host "[$($i+1)] $($scripts[$i].Name)"
    }
    Write-Host "[X] Retour"

    $choice = Read-Host "Sélectionnez un script"
    if ($choice -eq "X") { return }

    $selectedScript = $scripts[$choice - 1].FullName
    if ($selectedScript -match "\.ps1$") {
        Write-Host "`n🚀 Exécution de '$selectedScript'..." -ForegroundColor Green
        Start-Process "powershell.exe" -ArgumentList "-ExecutionPolicy Bypass -File `"$selectedScript`"" -NoNewWindow -Wait
    } elseif ($selectedScript -match "\.bat$") {
        Write-Host "`n🚀 Exécution de '$selectedScript'..." -ForegroundColor Green
        Start-Process "cmd.exe" -ArgumentList "/c `"$selectedScript`"" -NoNewWindow -Wait
    } else {
        Write-Host "❌ Type de fichier non supporté !" -ForegroundColor Red
    }
}

# Main Menu
while ($true) {
    Write-Host "`n===== 🛠️ TOOLBOX ADMINISTRATEUR 🛠️ =====" -ForegroundColor Cyan
    Write-Host "[1] Serveur"
    Write-Host "[2] Ordinateur"
    Write-Host "[3] Déploiement"
    Write-Host "[U] Mise à jour du toolbox"
    Write-Host "[X] Quitter"

    $input = Read-Host "Choisissez une option"
    switch ($input) {
        "1" { Run-Script "Serveur" }
        "2" { Run-Script "Ordinateur" }
        "3" { Run-Script "Déploiement" }
        "U" { Update-Toolbox }
        "X" { exit }
        default { Write-Host "❌ Sélection invalide, réessayez." -ForegroundColor Red }
    }
}
