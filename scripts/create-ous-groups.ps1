# create-ous-groups.ps1
# Lloyd's Demo (fictional company) - creates one OU and one security group per department,
# plus an OU for disabled (leaver) accounts.
# Run on DC01 in PowerShell (Admin), after the domain lloydsdemo.local exists.

# Stop at the first error instead of carrying on
$ErrorActionPreference = "Stop"

# Check we are in the right domain before creating anything
$expected = "lloydsdemo.local"
$actual = (Get-ADDomain).DNSRoot
if ($actual -ne $expected) {
    throw "Wrong domain: found '$actual' but expected '$expected'. Nothing was created."
}
$domain = (Get-ADDomain).DistinguishedName

$departments = "IT", "Engineering", "Finance", "HR", "Operations",
               "Sales", "Marketing", "Legal", "Customer-Support", "Procurement"

foreach ($dept in $departments) {
    # OU for the department, directly under the domain
    New-ADOrganizationalUnit -Name $dept -Path $domain

    # Security group for the department, stored inside its own OU
    New-ADGroup -Name "GRP-$dept" `
                -GroupScope Global `
                -GroupCategory Security `
                -Path "OU=$dept,$domain"

    Write-Host "Created OU and group for $dept"
}

# Holding area for accounts that belong to people who have left
New-ADOrganizationalUnit -Name "Disabled-Users" -Path $domain
Write-Host "Created Disabled-Users OU"
