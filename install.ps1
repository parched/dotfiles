# Set strict mode and error handling
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

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

# DOTFILES_WITH_LANGS and DOTFILES_NO_GIT_CONFIG are read by .chezmoi.yaml.tmpl
# when generating the config.
Write-Host "🚀  Initializing dotfiles"
if (-not (Test-Path "$env:USERPROFILE\.local\share\chezmoi\.git")) {
    chezmoi init parched
} else {
    # Already cloned, so just (re)generate the config in case the environment
    # variables have changed. Answers to earlier prompts are kept.
    chezmoi init
}
if (-not $?) {
    Write-Host "❌  Failed to initialize chezmoi."
    exit 1
}
chezmoi apply --less-interactive
if (-not $?) {
    Write-Host "❌  Failed to apply chezmoi."
    exit 1
}

Write-Host ""
Write-Host "Done."