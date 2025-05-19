# Set strict mode and error handling
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$CurrentExecutionPolicy = Get-ExecutionPolicy -Scope CurrentUser
if ($CurrentExecutionPolicy -ne "RemoteSigned") {
    Write-Host "🔒  Setting execution policy to RemoteSigned"
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
}

Write-Host ""
Write-Host "🤚  This script will setup .dotfiles for you."
Write-Host "    Press any key to continue or Ctrl+C to abort..." -NoNewline
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
Write-Host "`n"

$env:Path = [System.Environment]::GetEnvironmentVariable('Path','Machine') + ';' + [System.Environment]::GetEnvironmentVariable('Path','User')

# Install chezmoi
$chezmoiExists = Get-Command chezmoi -ErrorAction SilentlyContinue
if (-not $chezmoiExists) {
    Write-Host "👊  Installing chezmoi"
    winget install -e --id=twpayne.chezmoi
    if (-not $?) {
        Write-Host "❌  Failed to install chezmoi."
        exit 1
    }
}

# Install git
$gitExists = Get-Command git -ErrorAction SilentlyContinue
if (-not $gitExists) {
    Write-Host "🐙  Installing git"
    winget install -e --id Git.Git
    if (-not $?) {
        Write-Host "❌  Failed to install git."
        exit 1
    }
}

# Refresh path
$env:Path = [System.Environment]::GetEnvironmentVariable('Path','Machine') + ';' + [System.Environment]::GetEnvironmentVariable('Path','User')

# Check if chezmoi is initialized
if (Test-Path "$env:USERPROFILE\.local\share\chezmoi\.git") {
    Write-Host "🚸  chezmoi already initialized"
    Write-Host "    Reinitialize with: 'chezmoi init https://github.com/parched/dotfiles.git'"
}
else {
    Write-Host "🚀  Initializing dotfiles"
    chezmoi init https://github.com/parched/dotfiles.git
    if (-not $?) {
        Write-Host "❌  Failed to initialize chezmoi."
        exit 1
    }
}

Write-Host "Running winget config..."
winget configure "$env:USERPROFILE\.local\share\chezmoi\setup\configuration.dsc.yaml"
if (-not $?) {
    Write-Host "❌  Failed to configure winget."
    exit 1
}

Write-Host ""
Write-Host "Done."