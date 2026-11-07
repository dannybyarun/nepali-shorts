param(
    [string]$SkillsDir = "$env:USERPROFILE\.config\opencode\skills"
)

$ErrorActionPreference = "Stop"
$dest = Join-Path $SkillsDir "nepali-shorts"
New-Item -ItemType Directory -Force -Path $dest | Out-Null
Copy-Item (Join-Path $PSScriptRoot "SKILL.md") (Join-Path $dest "SKILL.md") -Force
Write-Host "Installed nepali-shorts skill to $dest"
