Param(
	[Alias("u")]
	[switch] $Upload,

	[Alias("d")]
	[switch] $Download,

	[Alias("c")]
	[switch] $Commit,

	[Alias("t")]
	[string[]] $Targets = 'this'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

$branch = 'master'
$crowdinConfigFileName = 'crowdin.yml'
$crowdinIdentityFileName = 'crowdin_identity.yml'
$crowdinIdentityDefaultPath = "$PSScriptRoot\$crowdinIdentityFileName"
$crowdinIdentityPath = "$crowdinIdentityDefaultPath"
$crowdinJarPath = "$PSScriptRoot\remote\crowdin-cli.jar"

function Crowdin-Download($commit) {
	Verify-Crowdin-Structure
	Crowdin-Execute 'download'
}

function Crowdin-Execute($command) {
	if (Get-Command 'crowdin' -ErrorAction SilentlyContinue) {
		& crowdin -b "$branch" --identity "$crowdinIdentityPath" $command

		if ($LastExitCode -ne 0) {
			throw "Last command failed."
		}
	} elseif ((Test-Path "$crowdinJarPath" -PathType Leaf) -and (Get-Command 'java' -ErrorAction SilentlyContinue)) {
		& java -jar "$crowdinJarPath" -b "$branch" --identity "$crowdinIdentityPath" $command

		if ($LastExitCode -ne 0) {
			throw "Last command failed."
		}
	} else {
		throw "Could not find crowdin executable!"
	}
}

function Crowdin-Upload {
	Verify-Crowdin-Structure
	Crowdin-Execute 'upload sources'
}

function Git-Commit {
	git reset

	if ($LastExitCode -ne 0) {
		throw "Last command failed."
	}

	git add -A .

	if ($LastExitCode -ne 0) {
		throw "Last command failed."
	}

	git diff-index --quiet HEAD

	if ($LastExitCode -ne 0) {
		git commit -m "Translations update"

		if ($LastExitCode -ne 0) {
			throw "Last command failed."
		}
	}

	git push origin "$branch" --recurse-submodules=on-demand

	if ($LastExitCode -ne 0) {
		throw "Last command failed."
	}
}

Push-Location "$PSScriptRoot"

function Verify-Crowdin-Structure {
	if (!(Test-Path "$crowdinConfigFileName" -PathType Leaf)) {
		throw "$crowdinConfigFileName could not be found, aborting."
	}

	if (Test-Path "$crowdinIdentityFileName" -PathType Leaf) {
		$crowdinIdentityPath = "$pwd\$crowdinIdentityFileName"
	} elseif (Test-Path "$crowdinIdentityDefaultPath" -PathType Leaf) {
		$crowdinIdentityPath = "$crowdinIdentityDefaultPath"
	} else {
		throw "Neither $crowdinIdentityFileName nor $crowdinIdentityDefaultPath could be found, aborting."
	}
}

function Execute-Target {
	if ($Upload) {
		Crowdin-Upload
	}

	if ($Download) {
		Crowdin-Download
	}

	if ($Commit) {
		Git-Commit
	}
}

try {
	for ($i = 0; ($i -lt 2) -and (!(Test-Path "$crowdinConfigFileName" -PathType Leaf)); $i++) {
		Set-Location ..
	}

	foreach ($target in $Targets) {
		if (($target) -and ($target -ne 'this')) {
			Push-Location "$target"

			try {
				Execute-Target
			} finally {
				Pop-Location
			}
		} else {
			Execute-Target
		}
	}
} finally {
	Pop-Location
}
