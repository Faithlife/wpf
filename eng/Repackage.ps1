$baseNuGetPackage = 'Microsoft.WindowsDesktop.App.Runtime.win-x64'
$baseNuGetVersion = '8.0.4'

$lastBuiltLocalPackage = (Get-ChildItem .\artifacts\obj\Microsoft.DotNet.Wpf.GitHub\Release\*.nuspec | Sort-Object LastWriteTime | Select-Object -last 1).Name
$lastBuiltLocalVersion = $lastBuiltLocalPackage.Replace('runtime.win-x64.Microsoft.DotNet.Wpf.GitHub.','').Replace('.nuspec','')

Write-Host "Repackaging $baseNuGetPackage.$baseNuGetVersion as $lastBuiltLocalVersion"

# download the Microsoft NuGet package
$baseNuGetFilePath = ".\artifacts\packages\$baseNuGetPackage.$baseNuGetVersion.nupkg"
if (!(Test-Path($baseNuGetFilePath)))
{
	Invoke-WebRequest "https://www.nuget.org/api/v2/package/$baseNuGetPackage/$baseNuGetVersion" -OutFile $baseNuGetFilePath
}

$packagingRoot = ".\artifacts\packaging\Release\x64\Microsoft.WindowsDesktop.App.Runtime"
if (Test-Path($packagingRoot))
{
	Remove-Item -Recurse -Force $packagingRoot
}

Expand-Archive -Path $baseNuGetFilePath -DestinationPath $packagingRoot

Remove-Item -Path "$packagingRoot\.signature.p7s"
Remove-Item -Path "$packagingRoot\Icon.png"

$nuspecPath = Resolve-Path -Path "$packagingRoot\Microsoft.WindowsDesktop.App.Runtime.win-x64.nuspec"
[xml]$nuspec = Get-Content $nuspecPath

$ns = @{
	cp = "http://schemas.openxmlformats.org/package/2006/metadata/core-properties"
	dc = "http://purl.org/dc/elements/1.1/"
	nuspec = $nuspec.DocumentElement.NamespaceURI
}

$nuspec.package.metadata.version = $lastBuiltLocalVersion
$nuspec.package.metadata.authors = "Faithlife"
$nuspec.package.metadata.icon
$nuspec.package.metadata.license."#text" = "MIT"
$nuspec.package.metadata.license.type = "expression"
$nuspec.package.metadata.licenseUrl = "https://licenses.nuget.org/MIT"
$nuspec.package.metadata.projectUrl = "https://github.com/Faithlife/wpf"
$nuspec.package.metadata.description = "Custom build of WPF built by Faithlife"
$nuspec.package.metadata.copyright = "© .NET Foundation and Contributors"
$nuspec.package.metadata.repository.url = "https://github.com/Faithlife/wpf.git"
$nuspec.package.metadata.repository.commit = $(git rev-parse HEAD)
$nuspec.Save($nuspecPath)

$psmdcpPath = Resolve-Path "$packagingRoot\package\services\metadata\core-properties\*.psmdcp"
[xml]$psmdcp = Get-Content $psmdcpPath
($psmdcp | Select-Xml '/cp:coreProperties/dc:creator' -Namespace $ns).Node.InnerText = $nuspec.package.metadata.authors
($psmdcp | Select-Xml '/cp:coreProperties/dc:description' -Namespace $ns).Node.InnerText = $nuspec.package.metadata.description
($psmdcp | Select-Xml '/cp:coreProperties/cp:version' -Namespace $ns).Node.InnerText = $nuspec.package.metadata.version
$psmdcp.Save($psmdcpPath)

$managedRoot = ".\artifacts\packaging\Release\x64\Microsoft.DotNet.Wpf.GitHub\lib\net8.0"
$nativeRoot = ".\artifacts\packaging\Release\x64\Microsoft.DotNet.Wpf.GitHub\runtimes\win-x64\native"

$runtimeListPath = Resolve-Path "$packagingRoot\data\RuntimeList.xml"
[xml]$runtimeList = Get-Content $runtimeListPath
foreach ($file in $runtimeList.FileList.File)
{
	if ($file.Type -eq 'Managed' || $file.Type -eq 'Resources')
	{
		$path = $file.Path.Replace('runtimes/win-x64/lib/net8.0/', '')
		if (Test-Path("$managedRoot\$path"))
		{
			$destination = Resolve-Path "$packagingRoot\$($file.Path)"
			Copy-Item -Path "$managedRoot\$path" -Destination $destination -Force
			$file.FileVersion = (Get-ChildItem $destination).VersionInfo.FileVersionRaw
			$file.AssemblyVersion = [Reflection.AssemblyName]::GetAssemblyName($destination).Version
		}
	}
	if ($file.Type -eq 'Native')
	{
		$path = $file.Path.Replace('runtimes/win-x64/native/', '')
		if (Test-Path("$nativeRoot\$path"))
		{
			$destination = Resolve-Path "$packagingRoot\$($file.Path)"
			Copy-Item -Path "$nativeRoot\$path" -Destination $destination -Force
			$file.FileVersion = (Get-ChildItem $destination).VersionInfo.FileVersionRaw
		}
	}
}
$runtimeList.Save($runtimeListPath)

$(git rev-parse HEAD) | Out-File "$packagingRoot\Microsoft.WindowsDesktop.App.versions.txt"
$lastBuiltLocalVersion | Out-File -Path "$packagingRoot\Microsoft.WindowsDesktop.App.versions.txt" -Append

$shippingPath = ".\artifacts\packages\Release\Shipping"
mkdir $shippingPath -Force | Out-Null
$repackagedPath = "$shippingPath\$baseNuGetPackage.$lastBuiltLocalVersion.nupkg"
Compress-Archive -Path "$packagingRoot\*" -DestinationPath $repackagedPath -Force
Write-Host $repackagedPath
