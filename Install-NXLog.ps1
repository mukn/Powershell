<## Install-NXLog
    This checks for an install of NXLog and installs the software if it is missing.
    
    This should only be installed on servers and must be run from an administrative
    user account.
#>

# Verify nxlog is not already installed
if ($(Get-Service -Name nxlog -ErrorAction SilentlyContinue)) {
    exit 0
}

# Determine logged services installed
$serviceExists = $false
$serviceNames = "DHCP Server", "DNS"
$path = "C:\"

foreach ($serviceName in $serviceNames) {
    $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
    if ($service) {
        $serviceExists = $true
    }
}

# Get files
if ($serviceExists) {
    Copy-Item -Path \\nac.local\noyesac\Installers\nxlog\nxlogWINEVT_DNS_DHCP\ -Destination C:\ -Recurse
    $path = "C:\nxlogWINEVT_DNS_DHCP"
} else {
    Copy-Item -Path \\nac.local\noyesac\Installers\nxlog\nxlogWINEVT_IIS\ -Destination C:\ -Recurse
    $path = "C:\nxlogWINEVT_IIS"
}

# Install nxlog
Set-Location $path
.\nxlog-install.bat
