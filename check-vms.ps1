param(
    [Parameter(Mandatory=$true)] [string] $user,
    [Parameter(Mandatory=$true)] [string] $pass,
    [Parameter(Mandatory=$true)] [string] $csvVM
)

#Connect to HCX Servers
Connect-HCXServer -Server 'irv-hcx-ent01.corp.ocwen.com' -User $user -Password $pass
Connect-HCXServer -Server 'atl-hcx-ent01.corp.ocwen.com' -User $user -Password $pass

#Create a new object to store a VM name and its sync status
$vmlistobj = New-Object psobject
$vmlistobj | Add-Member	-MemberType NoteProperty -Name Name -Value $null
$vmlistobj | Add-Member	-MemberType NoteProperty -Name Status -Value $null

#Import list of VMs to check from CSV file
$vmlist = Import-Csv -Header 'Name' -Path $csvVM

#Cache current HCX DR protected VMs into variable and initialize list of VMs to output
$current_reps = Get-HCXReplication
$vm_out = @()

#For each vm in the CSV file, grab the HCX replication object for that specific VM.  Store the VM name into the temp object and check to see if the
#name is null.  If null, report VM status as missing from replication.  If VM exists in HCX replication, report VM status as OK.  Store VM status
#object into output variable and move to next VM.

foreach($vm in $vmlist){
    $vmtemp = $vmlistobj | Select-Object *
	$check = $current_reps | where-object {$_.VM -match $vm.Name}
    
    $vmtemp.Name = $vm.Name
	if ($check -eq $null){
	   $vmtemp.Status = 'missing'
	}
	else{
	   $vmtemp.Status = 'ok'
	}
	$vm_out += $vmtemp
}

#create output file and print vm_out to file
$file = '.\vm-status.txt'
$vm_out | Add-Content -Path $file