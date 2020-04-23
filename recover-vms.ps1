param(
    [Parameter(Mandatory=$true)] [string] $HCXserver,
    [Parameter(Mandatory=$true)] [string] $user,
    [Parameter(Mandatory=$true)] [string] $pass,
    [Parameter(Mandatory=$true)] [string] $csvVM,
)

Connect-HCXServer -Server $HCXserver -User $user -Password $pass

$SourceSite = Get-HCXSite -server $HCXserver
$DestSite = Get-HCXSite -destination

$wave = Import-Csv -Header 'Name' -Path $csvVM
$replications = Get-HCXReplication

#$vms = Get-HCXVM -site $SourceSite

foreach($vm in $wave){
    $recover = $replications | where-object {$_.VM -match $vm.Name}	
	$snap = Get-HCXReplicationSnapshot -Replication $recover
	$recoverysnap = $snap[0]
    Set-HCXReplication -Replication $recover -Snapshot $recoverysnap -PowerOffVMAfterRecovery $true 
}