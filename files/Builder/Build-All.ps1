$invocationPath = Split-Path -Path $MyInvocation.MyCommand.Path -Parent

Invoke-Expression (Join-Path $invocationPath "Build-BootWim.ps1")
Invoke-Expression (Join-Path $invocationPath "Build-2016Wim.ps1")