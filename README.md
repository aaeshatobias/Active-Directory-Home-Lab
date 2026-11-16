# Active Directory Home Lab: Domain Controller, Users, Groups, and Group Policy

> **One-line summary:** An Active Directory lab in VirtualBox for the fictional company Lloyd's Demo, with a Windows Server domain controller and a Windows 11 client: OUs, groups, and users created with PowerShell, joiner, mover, and leaver changes, and Group Policy.

> **Note:** Lloyd's Demo, its people, and all data in this project are fictional and were created for learning. Nothing here is real, and no passwords are included.

**Status: Complete (2026-11-16).** All seven steps are done and verified: domain controller, OUs, groups, and users, a domain-joined Windows 11 client, joiner, mover, leaver, password reset, and account unlock tasks, and Group Policy.

## Overview
Lloyd's Demo is a fictional demolition contractor. In my [Microsoft Entra ID lab](https://github.com/aaeshatobias/iam-joiner-mover-leaver-lab) I built its access model in the cloud. This lab builds the same company on-premises: a Windows Server domain controller running Active Directory, a Windows 11 workstation joined to the domain, and the same departments, naming convention, and joiner-mover-leaver rules. Doing both lets me compare how identity is managed on servers I run and in Microsoft's cloud.

## Skills Demonstrated
- Installing and configuring Active Directory Domain Services (AD DS) and DNS
- Creating organizational units (OUs), security groups, and users, including bulk creation with PowerShell
- Joining a Windows client to a domain
- Joiner, mover, and leaver account changes, and contractor account expiration
- Password resets and account unlocks
- Group Policy (password, lockout, and screen-lock settings)
- Troubleshooting and technical documentation, including evidence handling

## Lab Environment
| Item | Detail |
|------|--------|
| Virtualization | Oracle VirtualBox (version 7.1.6) |
| Domain controller | Windows Server 2025 Standard Evaluation (Desktop Experience), name DC01, IP 192.168.10.10 |
| Client | Windows 11 Enterprise evaluation, name WS01, IP 192.168.10.20, joined to the domain |
| Domain | lloydsdemo.local (NetBIOS name LLOYDSDEMO) |
| Network | Internal network "labnet" between the two VMs; DC01 also has a NAT adapter for updates |
| DC01 resources | 4 GB memory, 2 processors, 50 GB dynamically allocated disk |

### Network Diagram
```
 [ WS01 ] -------- labnet (internal) -------- [ DC01 ] ---- NAT ---- Internet (updates only)
 Windows 11          192.168.10.0/24          Windows Server
 192.168.10.20                                192.168.10.10
                                              AD DS + DNS
```

## Company Structure
The same 10 departments as the Entra ID lab. Each has one OU and one security group named `GRP-<Department>`. A separate `Disabled-Users` OU holds accounts of people who have left.

| Department | OU | Group |
|------------|----|-------|
| IT | OU=IT | GRP-IT |
| Engineering | OU=Engineering | GRP-Engineering |
| Finance | OU=Finance | GRP-Finance |
| HR | OU=HR | GRP-HR |
| Operations | OU=Operations | GRP-Operations |
| Sales | OU=Sales | GRP-Sales |
| Marketing | OU=Marketing | GRP-Marketing |
| Legal | OU=Legal | GRP-Legal |
| Customer Support | OU=Customer-Support | GRP-Customer-Support |
| Procurement | OU=Procurement | GRP-Procurement |

### Users
The same fictional usernames as the Entra ID lab (see [users-sanitized.csv](users-sanitized.csv)). Passwords were entered at a prompt and are not stored anywhere in this repo.

| Username | Department | Purpose in the lab |
|----------|------------|--------------------|
| jnguyen | IT | Administrator-level user |
| skim | Engineering | Standard user |
| dsmith | Finance | Standard user |
| lpatel | HR | Standard user |
| mgarcia | Sales | Standard user |
| psingh | Sales | Mover: Sales to Marketing |
| rjohnson | Marketing | Contractor with an account expiration date |
| cmartinez | Procurement | Leaver |
| krodriguez | Customer Support | Standard user |
| atorres | Marketing | Standard user |

## What I Built
| Step | What I did | Status | Evidence |
|------|-----------|--------|----------|
| 1. Setup | Downloaded the Windows Server evaluation ISO, created the project folders | Done (2026-11-09) | n/a |
| 2. Server VM | Created DC01, installed Windows Server, set a fixed IP on the lab network, activated and updated it | Done (2026-11-09) | screenshots/02-dc01-network.png |
| 3. Domain | Installed AD DS and DNS and created the forest lloydsdemo.local | Done (2026-11-12) | screenshots/03-domain-created.png |
| 4. Structure and users | Created 10 OUs, 10 groups, and 10 users with PowerShell | Done (2026-11-12) | screenshots/04-ous-groups-users.png |
| 5. Client | Built WS01, set a fixed IP and DNS pointing to DC01, joined it to the domain, and signed in as a domain user | Done (2026-11-16) | screenshots/05-client-joined.png |
| 6. Admin tasks | Joiner, mover, leaver, contractor expiration, password reset, account unlock | Done (2026-11-16) | screenshots/06a to 06g |
| 7. Group Policy | Password and lockout policy on the domain; screen-lock policy on the Finance OU | Done (2026-11-16) | screenshots/07a to 07g |

## Admin Tasks Practiced
| Task | Steps | How I confirmed it worked |
|------|-------|---------------------------|
| Joiner (Taylor Brooks, Legal) | Create the user in the Legal OU, add to GRP-Legal | `Get-ADUser` shows the account in OU=Legal; group membership listed |
| Mover (psingh) | Remove the old group first, then add the new one; move the account to the new OU | `Get-ADPrincipalGroupMembership` shows only GRP-Marketing; account is in OU=Marketing |
| Leaver (cmartinez) | Disable the account, remove groups, move to the Disabled-Users OU | `Get-ADUser` shows Enabled False in OU=Disabled-Users |
| Contractor expiration (rjohnson) | Set an account expiration date with `Set-ADAccountExpiration` | Expiration date shown on the account |
| Password reset | `Set-ADAccountPassword -Reset`, then require a change at next sign-in | User signed in on WS01 with the new password |
| Account unlock | Locked dsmith with 5 bad passwords on WS01, confirmed with `Get-ADUser -Properties LockedOut`, fixed with `Unlock-ADAccount` | LockedOut changed from True to False; dsmith signed back in |

## Group Policy
| Policy | Where applied | Setting | Verified with |
|--------|---------------|---------|--------------|
| Password and lockout | Default Domain Policy | Minimum length 12, maximum age 90 days, history 24, complexity on, lock after 5 bad attempts for 30 minutes | `Get-ADDefaultDomainPasswordPolicy`; the lockout fired after exactly 5 bad attempts |
| Screen lock | Finance OU (GPO "Finance - Screen Lock") | Lock after 600 seconds idle, password required to unlock | `gpresult /r` as dsmith on WS01 lists the GPO under Applied Group Policy Objects |

## Scripts
- [scripts/create-ous-groups.ps1](scripts/create-ous-groups.ps1): creates the OUs and department groups. It checks that the domain is exactly `lloydsdemo.local` first and stops at the first error.
- [scripts/create-users.ps1](scripts/create-users.ps1): creates users from the CSV. It runs the same domain check, asks for the lab password at a prompt, and does not store it.

## Active Directory vs. Microsoft Entra ID
| | Active Directory (this lab) | Microsoft Entra ID (my IAM lab) |
|---|-----------------------------|----------------------------------|
| Where it runs | On servers I manage | Microsoft's cloud |
| Organizing accounts | OUs and Group Policy | Groups, with Conditional Access for sign-in rules |
| Same design in both | Same departments, same group naming, same joiner-mover-leaver rules | |
| What I learned | A policy linked to an OU applies by location, and I verify it with gpresult on a client | Access is controlled through groups and Conditional Access, and I verify it in the sign-in logs |

## Lessons Learned
1. **A domain name can't be fixed after the fact, so check it before you click Next.** I mistyped the domain name (swapped two letters) while promoting the server. My scripts failed with "The server is unwilling to process the request" because the location they targeted did not exist. I traced it by checking `whoami` and `Get-ADDomain`, restored the clean-install snapshot, and rebuilt the domain with the correct name. The scripts now verify the domain name before creating anything and stop at the first error.
2. **Take snapshots while the VM is powered off.** A snapshot of the running server froze at 99% and the VM had to be force-stopped. After shutting down properly, the snapshot worked. I now take snapshots only when the VM is off.
3. **A domain controller needs the DNS role and one clear address.** The first DNS test failed because DNS was not installed. After installing it, the server's second (NAT) adapter address showed up in DNS answers and confused the client. I disabled the NAT adapter, deleted the stale records, and kept only the lab network address.
4. **PowerShell must run as Administrator.** Setting the client's IP failed with "Access is denied" until I opened an elevated window. I also hit a typo (`New-NetIPAdress`) that PowerShell rejected, so I now read the error text before retrying.
5. **Windows Update can roll back a lab server.** DC01 spent several minutes undoing an update after a restart. I checked that the DNS, NTDS, Netlogon, and ADWS services were running and that the users were intact, then paused updates.
6. **Test a policy from the user's side.** The lockout and screen-lock policies were only proven once I locked dsmith out on WS01 and ran `gpresult` as her.

## Limitations
- This is a small lab with two virtual machines, not a production environment.
- It does not include a hybrid setup with Microsoft Entra Connect, a second domain controller, or backups.
- The Windows evaluation licenses expire, so the VMs are not kept running.

## Next Improvements
- Add a second domain controller
- Add a file share with permissions based on groups
- Connect it to Microsoft Entra ID with Entra Connect

## Repo Structure
```
README.md
.gitignore
users-sanitized.csv
scripts/
  create-ous-groups.ps1
  create-users.ps1
screenshots/            (redacted images only)
```
