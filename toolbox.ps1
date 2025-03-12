$GitHubRepo = "https://raw.githubusercontent.com/YOUR_GITHUB_USER/YOUR_REPO/main/scripts"
$Categories = @("Serveur", "Ordinateur", "Déploiement")

# Function: Fetch available scripts from GitHub
function Get-AvailableScripts($Category) {
    try {
        $url = "$GitHubRepo/$Category/"
        $files = Invoke-WebRequest -Uri $url -UseBasicParsing | Select-String -Pattern '(?<=href=")[^"]+\.(ps1|bat)"' | ForEach-Object { $_.Matches.Value -replace '"', '' }
        return $files
    } catch {
        Write-Host "❌ Impossible de récupérer les scripts de '$Category'" -ForegroundColor Red
        return @()
    }
}

# Function: Run a script from GitHub
function Run-Script($Category) {
    $scripts = Get-AvailableScripts -Category $Category
    if (-not $scripts) {
        Write-Host "❌ Aucun script trouvé pour '$Category'" -ForegroundColor Red
        return
    }

    Write-Host "`n📜 Scripts disponibles dans '$Category' :" -ForegroundColor Cyan
    for ($i = 0; $i -lt $scripts.Count; $i++) {
        Write-Host "[$($i+1)] $($scripts[$i])"
    }
    Write-Host "[X] Retour"

    $choice = Read-Host "Sélectionnez un script"
    if ($choice -eq "X") { return }

    $selectedScript = $scripts[$choice - 1]
    $scriptURL = "$GitHubRepo/$Category/$selectedScript"

    if ($selectedScript -match "\.ps1$") {
        Write-Host "`n🚀 Téléchargement et exécution de '$selectedScript'..." -ForegroundColor Green
        irm $scriptURL | iex
    } elseif ($selectedScript -match "\.bat$") {
        Write-Host "`n🚀 Téléchargement et exécution de '$selectedScript'..." -ForegroundColor Green
        $tempPath = "$env:TEMP\$selectedScript"
        Invoke-WebRequest -Uri $scriptURL -OutFile $tempPath
        Start-Process "cmd.exe" -ArgumentList "/c `"$tempPath`"" -NoNewWindow -Wait
    } else {
        Write-Host "❌ Type de fichier non supporté !" -ForegroundColor Red
    }
}

# Main Menu
while ($true) {
    Write-Host "`n===== 🛠️ TOOLBOX ADMINISTRATEUR (GitHub Edition) 🛠️ =====" -ForegroundColor Cyan
    Write-Host "[1] Serveur"
    Write-Host "[2] Ordinateur"
    Write-Host "[3] Déploiement"
    Write-Host "[X] Quitter"

    $input = Read-Host "Choisissez une option"
    switch ($input) {
        "1" { Run-Script "Serveur" }
        "2" { Run-Script "Ordinateur" }
        "3" { Run-Script "Déploiement" }
        "X" { exit }
        default { Write-Host "❌ Sélection invalide, réessayez." -ForegroundColor Red }
    }
}
