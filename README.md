# ArchiCrowdin

This tool is used as a submodule in our crowdin-powered projects that allows easier strings upload for automation purposes, especially in CI environments.

---

## Requirements

- **[Powershell Core](https://github.com/PowerShell/PowerShell)** (standard Powershell will also work)
- **[Java 7+](https://www.oracle.com/technetwork/java/javase/downloads/index.html)** (we suggest latest release, just JRE is enough)
- **[Crowdin CLI](https://support.crowdin.com/cli-tool/#installation)** (optional)

The tool will prefer to use your local installation of `crowdin`. If that is not possible, it'll use our own bundled version of **[Crowdin CLI](https://support.crowdin.com/cli-tool)** with its source located **[on GitHub](https://github.com/crowdin/crowdin-cli-2)**. We'll try to update our version on usual basis in order to match **[the latest version](https://downloads.crowdin.com/cli/v2/crowdin-cli.zip)** released by Crowdin.

If you're not using Crowdin CLI or otherwise have `crowdin` command unavailable in your environment, ensure that `java` command is recognized. This should be the case on Linux/OS X by default, but on Windows you might need to **[add java to your path](https://www.java.com/en/download/help/path.xml)** in order to achieve that. `java -version` command must work properly in the environment that is supposed to work with our tool.

---

## Setup

ArchiCrowdin should be included as a submodule in your local GitHub repo, either in its root, or up to two directories inside. Example command to achieve that would be `git submodule add https://github.com/JustArchiNET/ArchiCrowdin.git tools\ArchiCrowdin`. If you're not using `git`, you can also just include it as part of your project in appropriate subdirectory.

Your project **must** include valid `crowdin.yml` in its root directory. This file specifies all input strings and output translations. If you're already using any sort of crowdin integration in your project, most likely you're already meeting this point, otherwise, read **[configuration file](https://support.crowdin.com/configuration-file)** and create proper file.

---

## Identity

Assuming that you're meeting requirements and completed setup above, you only have crowdin identity left to create. This is actually usage and not setup, for reasons you'll learn below.

In general Crowdin identity specifies the project and API key that will be needed for strings upload. API key is considered a sensitive detail, therefore you could, in theory, create `crowdin_identity.yml` once and put it in the root of your project, and this setup is indeed supported, but discouraged. This case will work only with 100% private repos where you can be sure than nobody inappropriate will have access to those details, and even then it's a much better idea to not specify it in the repo at all.

Another supported, and this time **recommended** setup is to create `crowdin_identity.yml` out of `crowdin_identity_example.yml` during CI build process. It's enough to copy included `crowdin_identity_example.yml` as `crowdin_identity.yml` (either to our tool directory or project's directory root) and edit `CROWDIN_API_KEY` and `CROWDIN_PROJECT_IDENTIFIER` to match your project. API key should be defined as a secure variable (or equivalent) in your CI, while project identifier can be defined as a normal variable. This way, you can simply copy the example to target file, replace our placeholder values with actual ones, and then you can execute our scripts for the remaining part of the build process.

---

## Usage

As a low-level tool, you should use `archi.ps1` script. It supports following arguments:

- `-Upload` will push strings to Crowdin platform. This is equivalent to `crowdin upload sources`.
- `-Download` will pull translations from Crowdin platform. This is equivalent to `crowdin download`.
- `-Commit` will uncheck the files, commit the changes and push them to git repo. This is equivalent of `git reset`, `git add`, `git commit` and `git push`. This action is potentially dangerous and should be used only on clean repos, as `commit` will typically include all modified files.
- `-Pull` will ensure that tree is up-to-date before `upload`, `download` and `commit` actions. This is equivalent of `git checkout` followed by `git pull` done before each of those commands. Typically you want to use this during development, but not CI.

- `-Targets:{repos}` specifies target repos to perform actions on (separated by a comma). This argument is optional and defaults to `this` which targets the root project. You want to use this parameter if your project includes submodules that have their own `crowdin.yml` definitions. The order matters, so typically you'll want `this` repo to be your last.
- `-RecurseSubmodules` defines `--recurse-submodules` behaviour of `git` command when pushing or pulling. This argument is optional and defaults to `on-demand`. Check git manual for further explanation and available options.

Each parameter includes its own short alias that can be used instead of full name. The alias is made out of capital letters (e.g. `-u` for `-Upload`).

`Upload`, `Download` and `Commit` can all be specified at the same time. The tool will proceed in order of upload -> download -> commit (optionally with pulling before each step, if specified).

Git-based arguments such as `Commit` or `Pull` require from you to have `git` command available and specified `Targets` as git projects.

### Examples

```powershell
# The most common and expected usage, pushes strings to crowdin from this repo, defaults to -t:this
# This is what you want to use within your CI
& archi.ps1 -u

# Alternative version for projects with submodules that include their own crowdin.yml definitions
# This should be used mainly for development, not CIs, as each project should have its own CI process
& archi.ps1 -t:path\to\submodule,this -u

# Sometimes you might want to execute multiple actions at once, especially for syncing the tree (upload + download)
# You can do so by declaring multiple arguments, they'll be executed one after another in fixed order specified in usage
& archi.ps1 -u -d

# A complete development example that will do everything that is expected from crowdin integration
# This will upload, download and commit (with pulling first), for one of our submodules and the root project itself
# Since we also want to include new reference of our wiki submodule in the main project, we specified -rs:no which will avoid resetting it after being done with the wiki
& archi.ps1 -u -d -c -p -t:wiki,this -rs:no
```

---

## Contributions

All contributions are welcome, this tool was created in order to simplify our localization process in **[ArchiSteamFarm](https://github.com/JustArchiNET/ArchiSteamFarm)** project, with intention to come useful for various similar crowdin-powered projects. All pull requests are welcome.
