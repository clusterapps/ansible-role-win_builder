$invocationPath = Split-Path -Path $MyInvocation.MyCommand.Path -Parent

Invoke-Expression (Join-Path $invocationPath "Build-BootWim.ps1")
Invoke-Expression (Join-Path $invocationPath "Build-2012Wim.ps1")
Invoke-Expression (Join-Path $invocationPath "Build-2012R2Wim.ps1")
Invoke-Expression (Join-Path $invocationPath "Build-2016Wim.ps1")