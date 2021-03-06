# echo "make dir where build artifacts will be copied"
# md artifacts
# md artifacts\apps
# md artifacts\minuet

echo "Set Visual Studio env vars"
$path1='c:\Program Files (x86)\Microsoft Visual Studio 14.0\VC'
$path2='c:\Program Files\Microsoft Visual Studio 14.0\VC'
if ((Test-Path $path1) -eq $True) { pushd $path1 } 
elseif ((Test-Path $path2) -eq $True) { pushd $path2 } 
else { 
    echo 'abort: visual studio 2015 is not installed'
    exit -1 
} 

cmd /c "vcvarsall.bat&set" |
foreach {
  if ($_ -match "=") {
    $v = $_.split("="); set-item -force -path "ENV:\$($v[0])"  -value "$($v[1])"
  }
}
popd
write-host "`nVisual Studio 2015 Command Prompt variables set." -ForegroundColor Yellow

Function Build([string]$config, [string]$platform)
{
	echo "Starting $config $platform build"

	cd vendor\SFE-Minuet-DesktopClient
	msbuild Minuet.sln /t:clean /p:Configuration=$config /p:Platform=$platform
	msbuild Minuet.sln /t:rebuild /p:Configuration=$config /p:Platform=$platform
	$last=$?
	if ($last -eq $False) 
	{
		write-host "failed building $config $platform"
		exit -1 
	}
	
	cd ..\..
	msbuild Symphony.sln /t:clean /p:Configuration=$config /p:Platform=$platform
	msbuild Symphony.sln /t:rebuild /p:Configuration=$config /p:Platform=$platform
	$last=$?
	if ($last -eq $False) 
	{
		write-host "failed building $config $platform"
		exit -1 
	}
}

# update manifest.json with build version
$manifestFile = 'symphony\Symphony\manifest.json'
if ((Test-Path $manifestFile) -eq $False) {
	echo 'abort: manifest.json file does not exist: ' $manifestFile
	exit -1
}
$newVer=(get-childitem env:WRAPPER_VER).Value
$newVersion='"version": "' + $newVer + '",'
$content = (Get-Content $manifestFile)

# replace line with "version":
$newContent = $content -replace '^\s*"version"\s*:.*$', $newVersion
Set-Content $manifestFile $newContent

# build stuff
Build "Release" "x86"

exit 1
