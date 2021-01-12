param(
    [Parameter(Mandatory=$true)] [string] $user,
    [Parameter(Mandatory=$true)] [string] $pass,
    [Parameter(Mandatory=$true)] [string] $VMlist
)

Set-PowerCLIConfiguration -DefaultVIServerMode Multiple -Scope Session -confirm:$false
Connect-ViServer -Server $server1 -User $user -Password $pass
Connect-ViServer -Server $server2 -User $user -Password $pass

$vms_in_wave = Import-Csv -Header 'Name' -Path $VMlist
$vSphere = Get-VM
$vm_list = @()

foreach($vm in $vms_in_wave){
    $off = $vSphere | where-object {$_.Name -eq $vm.Name}
	Shutdown-VMGuest -VM $off -confirm:$false
	$vm_list += $off
}

$file = '.\powered-off.txt'
$vm_list | Add-Content -Path $file
