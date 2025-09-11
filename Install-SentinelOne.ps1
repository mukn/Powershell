<##     -- Install-SentinelOne.ps1 --

This script checks for a current install of Sentinel One, installs with the relevant site token as necessary,
verifies the service is running, then reports status back to the IT event log.

This is adapted from the https://wiki.secure-iss.com/Public/General/Sentinel-One-Deployment article on 10 
Sept 2025.

#>

# Scope variables
$apiUrl = ""
$source = "SentinelOne install test"
$hostname = $env:COMPUTERNAME
$description = "Sentinel One install on $hostname"

# Check if Sentinel One already installed.
$installFlag = $false
if ($(Get-Process -Name SentinelAgent -ErrorAction SilentlyContinue)) {
    $installFlag = $true
}

if (!$installFlag) {
    # Install SentinelOne via MSI
    # v1.0 - 25/01/2022

    # --== Configuration ==-- #
    ###########################

    $S1_MSI = "" # The source of the S1 MSI installer.
    $SiteToken = "" # Replace this with your site token - ask Secure-ISS for this.

    # # --== Initial Setup ==-- #
    # ###########################
    # $Host.UI.RawUI.BackgroundColor = 'Black';
    # Clear-Host;

    # # --== Function Definition ==-- #
    # #################################
    # function Print-Middle( $Message, $Color = "White" )
    # {
    #     Write-Host ( " " * [System.Math]::Floor( ( [System.Console]::BufferWidth / 2 ) - ( $Message.Length / 2 ) ) ) -NoNewline;
    #     Write-Host -ForegroundColor $Color $Message;
    # }

    # # --== Script Start ==-- #
    # ##########################

    # # Print Script Title
    # $Padding = ("=" * [System.Console]::BufferWidth);
    # Write-Host -ForegroundColor "Red" $Padding -NoNewline;
    # Print-Middle -Color "Red" "--== SentinelOne Installer ==--";
    # Print-Middle -Color "DarkRed" "PowerShell v$($PSVersionTable.PSVersion.Major).$($PSVersionTable.PSVersion.Minor)";
    # Write-Host -ForegroundColor "Red" $Padding;

    Start-Process -FilePath $S1_MSI -ArgumentList "SITE_TOKEN=$($SiteToken)", "/QUIET", "/NORESTART" -Wait;

    # Check for SentinelAgent
    if ($(Get-Process -Name SentinelAgent -ErrorAction SilentlyContinue)) {
        $installFlag = $true
    }
}

# Build JSON and send to API
if ($installFlag) {
    $level = "Success"
} else {
    $level = "Error"
}
$payload = @{
    Source = $source
    Description = $description
    Level = $level
} | ConvertTo-Json -Depth 3

Invoke-RestMethod -Uri $apiUrl -Method Post -Body $payload -ContentType "application/json"
