Param
(
    [parameter(Mandatory = $true)]
    [ValidateSet('amd64', 'arm64', '386')]
    [System.String]$Architecture,
    [parameter(Mandatory = $true)]
    [string]
    $Version
)

$sign = $false
if ($env:CERTIFICATE -ne "") {
    # create a base64 encoded value of your certificate using
    # certutil -encode 'path\certificate.pfx' 'path\certificate_base64.txt'
    # requires Windows Dev Kit 10.0.22000.0
    New-Item -ItemType directory -Path certificate
    Set-Content -Path certificate\certificate.txt -Value $env:CERTIFICATE
    certutil -decode certificate\certificate.txt certificate\certificate.pfx
    $sign = $true
}

New-Item -Path "." -Name "bin" -ItemType Directory
Copy-Item -Path "../../themes" -Destination "./bin" -Recurse

# download the file
$file = "posh-windows-$Architecture.exe"
$name = "oh-my-posh.exe"
$download = "https://github.com/jandedobbeleer/oh-my-posh/releases/download/v$Version/$($file)"
Invoke-WebRequest $download -Out "./bin/$($name)"
if ($sign) {
    & 'C:/Program Files (x86)/Windows Kits/10/bin/10.0.22000.0/x86/signtool.exe' sign /f ./certificate/certificate.pfx /p $env:CERTIFICATE_PASSWORD /t http://timestamp.digicert.com "./bin/$($name)"
}

# license
Invoke-WebRequest "https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/v$Version/COPYING" -Out "./bin/COPYING.txt"
$content = Get-Content '.\oh-my-posh.iss' -Raw
$content = $content.Replace('<VERSION>', $Version)
$ISSName = ".oh-my-posh-$Architecture-$Version.iss"
$content | Out-File -Encoding 'UTF8' $ISSName
# package content
$installer = "install-$Architecture"
ISCC.exe /F$installer $ISSName
if ($sign) {
    & 'C:/Program Files (x86)/Windows Kits/10/bin/10.0.22000.0/x86/signtool.exe' sign /f ./certificate/certificate.pfx /p $env:CERTIFICATE_PASSWORD /t http://timestamp.digicert.com "Output/$installer.exe"
}
# get hash
$zipHash = Get-FileHash "Output/$installer.exe" -Algorithm SHA256
$zipHash.Hash | Out-File -Encoding 'UTF8' "Output/$installer.exe.sha256"
