# create-users.ps1
# Lloyd's Demo (fictional company) - creates the test users from a CSV file,
# places each in their department OU, and adds them to their department group.
# The password is typed at a prompt. It is never stored in this script or the CSV.
# Run on DC01 in PowerShell (Admin), from the folder that contains users-sanitized.csv.

param(
    [string]$CsvPath = ".\users-sanitized.csv"
)

# Stop at the first error instead of carrying on
$ErrorActionPreference = "Stop"

# Check we are in the right domain before creating anything
$expected = "lloydsdemo.local"
$actual = (Get-ADDomain).DNSRoot
if ($actual -ne $expected) {
    throw "Wrong domain: found '$actual' but expected '$expected'. Nothing was created."
}
$domain = (Get-ADDomain).DistinguishedName
$upnSuffix = $expected

# Ask for the lab password once (typing is hidden)
$password = Read-Host -Prompt "Enter the lab password for the test users" -AsSecureString

Import-Csv $CsvPath | ForEach-Object {
    $dept = $_.Dept

    New-ADUser -Name "$($_.First) $($_.Last)" `
               -GivenName $_.First `
               -Surname $_.Last `
               -DisplayName "$($_.First) $($_.Last)" `
               -SamAccountName $_.User `
               -UserPrincipalName "$($_.User)@$upnSuffix" `
               -Department ($dept -replace "-", " ") `
               -Path "OU=$dept,$domain" `
               -AccountPassword $password `
               -Enabled $true `
               -ChangePasswordAtLogon $false

    Add-ADGroupMember -Identity "GRP-$dept" -Members $_.User

    Write-Host "Created $($_.User) in $dept"
}
