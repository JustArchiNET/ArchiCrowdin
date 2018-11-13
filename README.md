# ArchiCrowdinCLI

This tool is used as a submodule in our crowdin-powered projects that allows easier strings upload for automation purposes, especially in CI environments.

---

## Requirements

- **[Powershell Core](https://github.com/PowerShell/PowerShell)** (standard Powershell will also work)
- **[Java 7+](https://www.oracle.com/technetwork/java/javase/downloads/index.html)** (we suggest latest release)
- **[Crowdin CLI](https://support.crowdin.com/cli-tool/#installation)** (optional)

The tool will prefer to use your local installation of `crowdin`. If that is not possible, it'll use our own bundled version of **[Crowdin CLI](https://support.crowdin.com/cli-tool)** with its source located **[on GitHub](https://github.com/crowdin/crowdin-cli-2)**. We'll try to update our version on usual basis in order to match **[the latest version](https://downloads.crowdin.com/cli/v2/crowdin-cli.zip)** released by Crowdin.

---

## Setup

ArchiCrowdinCLI should be included as a submodule in your local GitHub repo, either in its root, or one folder above. Example command to achieve that would be `git submodule add https://github.com/JustArchiNET/ArchiCrowdinCLI.git tools\ArchiCrowdinCLI`. If you're not using `git`, you can also just include it as part of your project in appropriate subdirectory.

Your project **must** include valid `crowdin.yml` in its root directory. This file specifies all input strings and output translations. If you're already using any sort of crowdin integration in your project, most likely you're already meeting this point, otherwise, read **[configuration file](https://support.crowdin.com/configuration-file)** and create proper file.

---

## Identity

Assuming that you're meeting requirements and completed setup above, you only have crowdin identity left to create. This is actually usage and not setup, for reasons you'll learn below.

In general Crowdin identity specifies the project and API key that will be needed for strings upload. API key is considered a sensitive detail, therefore you could, in theory, create `crowdin_identity.yml` once and put it in the root of your project, and this setup is indeed supported, but discouraged. This case will work only with 100% private repos where you can be sure than nobody inappropriate will have access to those details, and even then it's a much better idea to not specify it in the repo at all.

Another supported, and this time **recommended** setup is create `crowdin_identity.yml` out of `crowdin_identity_example.yml` during CI build process. It's enough to copy included `crowdin_identity_example.yml` as `crowdin_identity.yml` (either to our tool directory or project's directory root) and edit `CROWDIN_API_KEY` and `CROWDIN_PROJECT_IDENTIFIER` to match your project. API key should be defined as a secure variable (or equivalent) in your CI, while project identifier can be defined as a normal variable. This way, you can simply copy the example to target file, replace our placeholder values with actual ones, and then you can execute our scripts for the remaining part of the build process.

---

## Usage

As a low-level tool, you should use `archi_core.ps1` script. It supports following arguments:

- `-targets:{repos}` specifies target repos to perform actions on (separated by a comma). This argument is optional and defaults to `this` which targets the root project. You want to use this parameter if your project includes submodules that have their own `crowdin.yml` definitions. The order matters, so typically you'll want `this` repo to be your last.
- `-upload` will push strings to Crowdin platform. This is equivalent to `crowdin upload sources`.
- `-download` will pull translations from Crowdin platform. This is equivalent to `crowdin download`.
- `-commit` will uncheck the files, commit the changes and push them to git repo. This is equivalent of `git reset`, `git add`, `git commit` and `git push`. This action is potentially dangerous and should be used only on clean repos, as `commit` will typically include all modified files.

Each parameter includes its own short alias that can be used instead of full name. The alias right now is always equal to the first letter.

`upload`, `download` and `commit` can all be specified at the same time. The tool will proceed in order of upload -> download -> commit.

### Examples

```ps
& archi_core.ps1 -u # The most common and expected usage, pushes strings to crowdin from this repo, defaults to -t:this
& archi_core.ps1 -t:path\to\submodule,this -u # If your project includes submodules with their own crowdin.yml definitions, you can specify multiple repos at once, do not forget about the root (`this`) repo (if wanted)
& archi_core.ps1 -u -d # You can use multiple actions at once, they'll be executed one after another
& archi_core.ps1 -u -d -c -t:wiki,this # Upload, download and commit, for one of our submodules and the root project itself
```

---

## Contributions

All contributions are welcome, this tool was created in order to simplify our localization process in **[ArchiSteamFarm](https://github.com/JustArchiNET/ArchiSteamFarm)** project, with intention to come useful for various similar crowdin-powered projects. All pull requests are welcome.
