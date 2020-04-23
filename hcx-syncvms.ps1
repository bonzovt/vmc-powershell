param(
    [Parameter(Mandatory=$true)] [string] $user,
    [Parameter(Mandatory=$true)] [string] $pass,
    [Parameter(Mandatory=$true)] [string] $csvVM
)

#Connect to HCX Servers
Connect-HCXServer -Server 'irv-hcx-ent01.corp.ocwen.com' -User $user -Password $pass
Connect-HCXServer -Server 'atl-hcx-ent01.corp.ocwen.com' -User $user -Password $pass

#Import VMs from CSV file into a var
$vms_in_wave = Import-Csv -Header 'Name' -Path $csvVM

#Cache output of all current replications into var
$current_reps = Get-HCXReplication

#for every vm in the CSV file, get the replication object and force a sync for that replication using Set-HCXReplication -ForceSync
foreach($vm in $vms_in_wave){
    $rep = $current_reps | where-object {$_.VM -match $vm.Name}
    Set-HCXReplication -ForceSync -Replication $rep
}