param(
 [Parameter(Mandatory=$true)] [string] $refreshToken, 
 [Parameter(Mandatory=$true)] [string] $csvFile,
 [Parameter(Mandatory=$true)] [string] $orgName,
 [Parameter(Mandatory=$true)] [string] $sddcName
 )
 
#Connect to vmc server and nsxt
Connect-VmcServer -RefreshToken $refreshToken
Connect-NSXTProxy -RefreshToken $refreshToken -OrgName $orgName -SDDCName $sddcName
$P = Import-Csv -Header 'name','gateway' -Path $csvFile
foreach($network in $P) {
  New-NSXTSegment -Name $network.name -Gateway $network.gateway 
  Write-Host $network.name
}