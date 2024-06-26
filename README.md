# Faithlife.WPF

[![Build Status](https://dev.azure.com/Faithlife/WPF/_apis/build/status/Faithlife.wpf?branchName=stable)](https://dev.azure.com/Faithlife/WPF/_build/latest?definitionId=11&branchName=stable) [![MIT License](https://img.shields.io/badge/license-MIT-green.svg)](https://github.com/Faithlife/wpf/blob/stable/LICENSE.TXT)

This is a custom build of [Windows Presentation Foundation](https://github.com/dotnet/wpf) maintained by [Faithlife](https://faithlife.codes/).
The `stable` branch (7.x) is based off the `release/7.0` branch and is suitable to use with .NET 7.0 applications.
The `master` branch is also currently 7.x but may eventually be updated to track .NET 8.0 for pre-release testing.
The [Release Notes](ReleaseNotes.md) list the differences from the official release.

See the [WPF Roadmap](roadmap.md) to learn about project priorities, status and ship dates.

### Consuming

To use Faithlife.Wpf, build a regular WPF application (`dotnet new wpf`). Add the [Faithlife WPF package feed](https://dev.azure.com/Faithlife/WPF/_artifacts/feed/Public)
to your `NuGet.config`:

```xml
<configuration>
  <packageSources>
    <add key="Faithlife WPF" value="https://pkgs.dev.azure.com/Faithlife/WPF/_packaging/Public/nuget/v3/index.json" />
  </packageSources>
</configuration>
```

In your CSPROJ file, update the Microsoft.WindowsDesktop.App reference:

```xml
<ItemGroup>
  <FrameworkReference Update="Microsoft.WindowsDesktop.App" RuntimeFrameworkVersion="7.0.6-faithlife.1.23255.3" />
</ItemGroup>
```

### Building

* To build a dev package: `build.cmd -c Release -platform x64 -test -pack`
  * To use a unique version number, add `/p:OfficialBuildId=YYYYMMDD.BUILD`, e.g., `/p:OfficialBuildId=20230505.3`.
* All commits pushed to the `stable` branch will build a CI package that will be pushed to the Azure Artifacts feed.
* [Contributing guide](Documentation/contributing.md)

* **First time setup**: If you have problems building for the first time, you may have an incorrect local VS 2022 configuration. To correct this:
  1. Run the `Visual Studio Installer`
  2. In `More` menu for VS 2022, choose `Import configuration` select the file `Documentation\wpf.vsconfig`
  3. Follow the prompts to install everything needed

* **Missing .net SDK**: It is possible to not have the proper SDK for building. If the configuration update above doesn't resolve your build issue install the latest 6.0.xxx (currently `6.0.304`) from [Microsoft's site](https://dotnet.microsoft.com/en-us/download/dotnet/6.0).

## Using a locally built package

* You can't just use the built package directly. This is only a first step compile that needs to be "repackaged" into a usable state.
  1. Ensure you're running [Powershell 7.3.1](https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell-on-windows?view=powershell-7.3) or later.
  2. In your root wpf folder run .\eng\Repackage.ps1
  3. Move the file located in `.\artifacts\packages\Release\Shipping\` To the location you store local testing nuget packages.
  4. Update the version in your project to match the built version `7.0.6-dev.23255.3`

## Issues

Open an issue on this repo for problems _specifically with_ this package. All other issues should be opened on [dotnet/wpf](https://github.com/dotnet/wpf/issues).

## License

WPF is licensed under the [MIT license](LICENSE.TXT).
