param(
    [Parameter(Mandatory=$true)] [string] $HCXserver,
    [Parameter(Mandatory=$true)] [string] $vCenter,
    [Parameter(Mandatory=$true)] [string] $user,
    [Parameter(Mandatory=$true)] [string] $pass,
    [Parameter(Mandatory=$true)] [string] $csvVM,
    [Parameter(Mandatory=$true)] [string] $csvNetwork
)

#Connect to single HCX site and vCenter
Connect-HCXServer -Server $HCXserver -User $user -Password $pass
Connect-VIServer -Server $vCenter -User $user -Password $pass

#Cache vars for HCX source and destination sites
$SourceSite = Get-HCXSite -server $HCXserver
$DestSite = Get-HCXSite -destination

#Set vars that define RPO and snapshot values
$RPOIntervalMinutes = 15
$SnapshotIntervalMinutes = 60
$SnapshotNumber = 1

#Set vars that define VMC targets for replications, which cluster will the VMs land in VMC
$TargetDatastore = Get-HCXDatastore -site $DestSite -name 'WorkloadDatastore (2)'
$TargetCompute = Get-HCXContainer -site $DestSite -Name 'Compute-ResourcePool-3'
$TargetFolder = Get-HCXContainer -site $DestSite -name 'SDDC-Datacenter'

#Cache vars that import a CSV file with list of VMs and source/destination network mappings
$vmlist = Import-Csv -Header 'Name' -Path $csvVM
$netmap = Import-Csv -Path $csvNetwork

#Cache vars that import local HCX VM object, vSphere VM objects, destination networks and current VMs protected by HCX
$vms = Get-HCXVM -site $SourceSite
$vSphere = Get-VM
$destnetworks = Get-HCXNetwork -site $DestSite
$currentreps = Get-HCXReplication

#Initialize object var to store output data
$vm_out = @()

#For each VM (row) listed in the CSV file (vmlist), first retrieve the corresponding HCX VM object, then check to see if the VM is
#currently being replicated by HCX.  If it is replicating, mark it as replicating and move to next VM.  If not, see if the VM exists in
#the vSphere inventory.  If it does not exit, mark it as missing and move to the next VM.  If it does exist, first select the corresponding
#vSphere VM object.  Then grab the source network(s) from the vSphere VM object and initialize a NetworkMapping variable.  For each source
#network, create a network mapping with the source and destination networks.  Create a a new replication variable using all of the parameters
#defined earlier and start a new replication within HCX DR.  Once the loop has finished, print the output of the script to a file named
#vms-added.txt in the root directory.

foreach($row in $vmlist){
    $vm = $vms | where-object {$_.Name -eq $row.Name}
    $isreplicating = $currentreps | where-object {$_.VM -match $row.Name}
	
	#If the VM is currently not replicating within HCX
	if ($isreplicating -eq $null){
	    
	    #If the VM exists within vSphere
		if ($vm -ne $null){
	       $vSphereVM = $vSphere | where-object {$_.Name -eq $vm.Name}
		   $netS = Get-VirtualPortGroup -vm $vSphereVM
		   $SourceNetwork = Get-HCXNetwork -Name $netS.name -site $SourceSite
	       $NetworkMapping = @()
   
           #For every source network assigned to vNIC(s) attached to the VM
		   foreach ($network in $SourceNetwork){
               $temp = $netmap | where-object {$_.Source -eq $network.Name}
			   $DestNetwork = $destnetworks | where-object {$_.Name -eq $temp.Dest}
		       $NetworkMapping += New-HCXNetworkMapping -SourceNetwork $network -DestinationNetwork $DestNetwork
		    }
		
	       #Define replication variable using all parameters
		   $rep = New-HCXReplication -DestinationSite $DestSite `
             -NetworkMapping $NetworkMapping `
             -RPOIntervalMinutes $RPOIntervalMinutes `
             -SnapshotIntervalMinutes $SnapshotIntervalMinutes `
             -SnapshotNumber $SnapshotNumber `
             -SourceSite $SourceSite `
             -TargetDatastore $TargetDatastore `
             -TargetComputeContainer $TargetCompute `
             -TargetDataCenter $TargetFolder `
             -NetworkCompressionEnabled $true `
             -VM $vm
       
	       #Kick off VM protection in HCX DR
		   Start-HCXReplication -Replication $rep -Confirm:$false
	       $vm_out += $rep
	    }
	    else{
	       $vm_out += $row.Name + ' is missing'
		}
	}
	else{
	   $vm_out += $row.Name + ' is already syncing'
	}
}

#create output file and print vm_list to file
$file = '.\vms-added.txt'
$vm_out | Add-Content -Path $file

