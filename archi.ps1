Param(
	[Alias("u")]
	[switch] $Upload,

	[Alias("d")]
	[switch] $Download,

	[Alias("c")]
	[switch] $Commit,

	[Alias("p")]
	[switch] $Pull,

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
	if ($Pull) {
		Git-Pull
	}

	Verify-Crowdin-Structure
	Crowdin-Execute 'download'
}

function Crowdin-Execute($command) {
	if (Get-Command 'crowdin' -ErrorAction SilentlyContinue) {
		& crowdin -b "$branch" --identity "$crowdinIdentityPath" $command
		Throw-On-Error
	} elseif ((Test-Path "$crowdinJarPath" -PathType Leaf) -and (Get-Command 'java' -ErrorAction SilentlyContinue)) {
		& java -jar "$crowdinJarPath" -b "$branch" --identity "$crowdinIdentityPath" $command
		Throw-On-Error
	} else {
		throw "Could not find crowdin executable!"
	}
}

function Crowdin-Upload {
	if ($Pull) {
		Git-Pull
	}

	Verify-Crowdin-Structure
	Crowdin-Execute 'upload sources'
}

function Git-Commit {
	if ($Pull) {
		Git-Pull
	}

	git reset
	Throw-On-Error

	git add -A .
	Throw-On-Error

	# Git commit will fail if there are no changes to commit
	# Therefore, we'll call diff-index first and commit only if there are changes to be done
	# This way we can properly catch potential git commit errors
	git diff-index --quiet HEAD

	if ($LastExitCode -ne 0) {
		git commit -m "Translations update"
		Throw-On-Error
	}

	git push origin "$branch" --recurse-submodules=on-demand
	Throw-On-Error
}

function Git-Pull {
	git checkout "$branch"
	Throw-On-Error

	git pull origin "$branch" --recurse-submodules=on-demand
	Throw-On-Error
}

function Target-Execute {
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

function Throw-On-Error {
	if ($LastExitCode -ne 0) {
		throw "Last command failed."
	}
}

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

Push-Location "$PSScriptRoot"

try {
	for ($i = 0; ($i -lt 3) -and (!(Test-Path "$crowdinConfigFileName" -PathType Leaf)); $i++) {
		Set-Location ..
	}

	if (!(Test-Path "$crowdinConfigFileName" -PathType Leaf)) {
		throw "$crowdinConfigFileName could not be found, aborting."
	}

	foreach ($target in $Targets) {
		if (($target) -and ($target -ne 'this')) {
			Push-Location "$target"

			try {
				Target-Execute
			} finally {
				Pop-Location
			}
		} else {
			Target-Execute
		}
	}
} finally {
	Pop-Location
}
