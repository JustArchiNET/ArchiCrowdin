Set-StrictMode -Version Latest

Push-Location "$PSScriptRoot"

try {
	& archi_core.ps1 --upload --download
} finally {
	Pop-Location
}

pause
