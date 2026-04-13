$ErrorActionPreference = "Stop"

Write-Host "======================================" -ForegroundColor Cyan
Write-Host "    Starting Environment Setup" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan

# 1. Download and install Git
$gitInstallerPath = "$env:TEMP\git_installer.exe"
$gitUrl = "https://github.com/git-for-windows/git/releases/download/v2.44.0.windows.1/Git-2.44.0-64-bit.exe"

if (!(Get-Command "git" -ErrorAction SilentlyContinue)) {
    Write-Host "`n[1/4] Git not found. Downloading..." -ForegroundColor Yellow
    try {
        Invoke-WebRequest -Uri $gitUrl -OutFile $gitInstallerPath
        Write-Host "Download success! Starting silent install..." -ForegroundColor Green
        Write-Host "WARNING: If UAC prompts, please click YES!" -ForegroundColor Yellow
        Start-Process -FilePath $gitInstallerPath -ArgumentList "/VERYSILENT /NORESTART /NOCANCEL /SP- /CLOSEAPPLICATIONS /RESTARTAPPLICATIONS /COMPONENTS=icons,ext,ext\reg,ext\reg\shellhere,ext\reg\guihere,assoc,assoc_sh" -Wait
        
        $env:PATH += ";C:\Program Files\Git\cmd"
        Write-Host "Git installed!" -ForegroundColor Green
    } catch {
        Write-Host "Failed to install Git: $_" -ForegroundColor Red
        exit
    }
} else {
    Write-Host "`n[1/4] Git already installed. Skipping..." -ForegroundColor Green
}

# 2. Download and install Flutter
$flutterDir = "D:\flutter_sdk"
$flutterZip = "$env:TEMP\flutter.zip"
$flutterUrl = "https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_3.19.5-stable.zip"

if (!(Get-Command "flutter" -ErrorAction SilentlyContinue) -and !(Test-Path "$flutterDir\flutter\bin\flutter.bat")) {
    if (!(Test-Path $flutterDir)) {
        New-Item -ItemType Directory -Path $flutterDir -Force | Out-Null
    }
    
    Write-Host "`n[2/4] Flutter not found. Downloading SDK (approx 1 GB)..." -ForegroundColor Yellow
    try {
        Invoke-WebRequest -Uri $flutterUrl -OutFile $flutterZip
        Write-Host "Download success! Extracting (takes a few minutes)..." -ForegroundColor Green
        Expand-Archive -Path $flutterZip -DestinationPath $flutterDir -Force
    } catch {
        Write-Host "Failed to install Flutter: $_" -ForegroundColor Red
        exit
    }
} else {
    Write-Host "`n[2/4] Flutter detected. Skipping download..." -ForegroundColor Green
}

# 3. Setting Environment Variables
Write-Host "`n[3/4] Configuring PATH..." -ForegroundColor Yellow
$flutterBinPath = "$flutterDir\flutter\bin"

$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($userPath -notmatch [regex]::Escape($flutterBinPath)) {
    [Environment]::SetEnvironmentVariable("Path", $userPath + ";$flutterBinPath", "User")
    Write-Host "Added to User PATH: $flutterBinPath" -ForegroundColor Green
} else {
    Write-Host "PATH already contains Flutter." -ForegroundColor Green
}

$env:PATH += ";$flutterBinPath"

# 4. Run flutter doctor
Write-Host "`n[4/4] Running flutter doctor to initialize..." -ForegroundColor Yellow
flutter doctor

Write-Host "======================================" -ForegroundColor Cyan
Write-Host " Environment setup complete! " -ForegroundColor Green
Write-Host " You may need to restart your terminal or VSCode. " -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
