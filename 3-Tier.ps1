<#
Script to Create a 3 Tier Environment. It will consist of a Front end Load Balancer , which will communicate with a IIS Server over Port 80 which will inturn 
communicate with a DB Server over port 1433
#>


#Install and Import AZ Module
Install-Module az
Import-Module az

#connect to azure portal

Connect-AzAccount



#Find RG and Sub Details

Get-AzSubscription

$rg = Get-AzResourceGroup

$rgName = $rg.ResourceGroupName
$location = $rg.Location
$rgName

#Create VNET and Subnets' for both VM's
$subnet1 = New-AzVirtualNetworkSubnetConfig -Name "Subnet1" -AddressPrefix '10.0.1.0/26'

$subnet2 = New-AzVirtualNetworkSubnetConfig -Name "Subnet2" -AddressPrefix '10.0.2.0/26'

$vnet = New-AzVirtualNetwork -Name "myvnet" -ResourceGroupName "$rgName" -Location $location -AddressPrefix "10.0.0.0/16" -Subnet $subnet1,$subnet2

#Create Public Ip's and Front End Load Balancer Config

$pip1 = New-AzPublicIpAddress -Name "pip1" -ResourceGroupName "$rgName" -Location $location -AllocationMethod Static -Sku Standard

$pip2 = New-AzPublicIpAddress -Name "pip2" -ResourceGroupName "$rgName" -Location $location -AllocationMethod Static -Sku Standard

$pip3 = New-AzPublicIpAddress -Name "pip3" -ResourceGroupName "$rgName" -Location $location -AllocationMethod Static -Sku Standard

$feip = New-AzLoadBalancerFrontendIpConfig -Name "myFrontEnd" -PublicIpAddressId "/subscriptions/964df7ca-3ba4-48b6-a695-1ed9db5723f8/resourceGroups/1-a4f2a064-playground-sandbox/providers/Microsoft.Network/publicIPAddresses/pip3"
$bepool = New-AzLoadBalancerBackendAddressPoolConfig -Name 'myBackEndPool'

$healthprobe = New-AzLoadBalancerProbeConfig -Name 'myHealthProbe' -Protocol 'tcp' -Port '80' -IntervalInSeconds '360' -ProbeCount '5' 

$rule = New-AzLoadBalancerRuleConfig -Name 'myHTTPRule' -Protocol 'tcp' -FrontendPort '80' -BackendPort '80' -IdleTimeoutInMinutes '15' -FrontendIpConfiguration $feip -BackendAddressPool $bepool -EnableTcpReset -DisableOutboundSNAT


New-AzLoadBalancer -ResourceGroupName $rgName -Name 'myLoadBalancer' -Location $location -Sku 'Standard' -FrontendIpConfiguration $feip -BackendAddressPool $bePool -LoadBalancingRule $rule -Probe $healthprobe



#Get Subnet Details

$frontendsubnet = Get-AzVirtualNetworkSubnetConfig -Name "Subnet1" -VirtualNetwork $vnet
$backendsubnet = Get-AzVirtualNetworkSubnetConfig -Name "Subnet2" -VirtualNetwork $vnet

#Create Network Security Rules for Web VM to allow RDP and Internet Access to web URL

$rule1 = New-AzNetworkSecurityRuleConfig -Name 'AllowAccesstoFrontEndFromInternet' -Description 'Allow Access to Front End From Internet' -Access Allow -Protocol Tcp -Direction Inbound -Priority 100 -SourceAddressPrefix Internet -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 80

$rule2 = New-AzNetworkSecurityRuleConfig -Name 'AllowSecureAccesstoFrontEndFromInternet' -Description 'Allow Secure Access to Front End From Internet' -Access Allow -Protocol Tcp -Direction Inbound -Priority 200 -SourceAddressPrefix Internet -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 443

$rule3 = New-AzNetworkSecurityRuleConfig -Name 'AllowAccesstoFrontEndForRDP' -Description 'Allow Access to Front End For RDP' -Access Allow -Protocol Tcp -Direction Inbound -Priority 300 -SourceAddressPrefix Internet -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 3389


#Create NSG for Web VM and associate rules above

New-AzNetworkSecurityGroup -ResourceGroupName $rgName -Location $location -Name 'nsg1' -SecurityRules $rule1,$rule2,$rule3

$nsg1 = Get-AzNetworkSecurityGroup -Name "nsg1"

#Associate NSG Web VM to Subnet 1 

Set-AzVirtualNetworkSubnetConfig -Name "Subnet1" -VirtualNetwork $vnet -NetworkSecurityGroup $nsg1 -AddressPrefix '10.0.1.0/26'

#Create Rule$nic between Web SUbnet and DB Subnet and Internet to DB Server RDP


$rule4= New-AzNetworkSecurityRuleConfig -Name 'AllowAccesstoDBfromWeb' -Description 'Allow Access to DB from Web' -Access Allow -Protocol Tcp -Direction Inbound -Priority 100 -SourceAddressPrefix '10.0.1.0/26' -SourcePortRange * -DestinationAddressPrefix *  -DestinationPortRange 1433
$rule5 = New-AzNetworkSecurityRuleConfig -Name 'AllowAccesstoBackendEndForRDP' -Description 'Allow Access to Backend End For RDP' -Access Allow -Protocol Tcp -Direction Inbound -Priority 200 -SourceAddressPrefix Internet -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 3389

#Create NSG for DB VM and associate rules above
$nsg2 = New-AzNetworkSecurityGroup -ResourceGroupName $rgName -Location $location -Name 'nsg2' -SecurityRules $rule4,$rule5

Set-AzNetworkSecurityGroup -NetworkSecurityGroup $nsg2 

#Attach nsg DB VM to backend subnet

Set-AzVirtualNetworkSubnetConfig -VirtualNetwork $vnet -Name 'Subnet2' -AddressPrefix '10.0.2.0/26' -NetworkSecurityGroup $nsg2

#Create NIC for VM's

$nicVM1 = New-AzNetworkInterface -ResourceGroupName $rgName -Location $location -Name 'nicVM1' -PublicIpAddress $pip1 -NetworkSecurityGroup $nsg1 -Subnet $frontendsubnet -LoadBalancerBackendAddressPool $bepool

$nicVM2 = New-AzNetworkInterface -ResourceGroupName $rgName -Location $location -Name 'nicVM2' -PublicIpAddress $pip2 -NetworkSecurityGroup $nsg2 -Subnet $backendsubnet

#Create Web and DB VM

$cred = Get-Credential

$vmConfig = New-AzVMConfig -VMName 'myVm1' -VMSize 'Standard_DS1_v2' |  Set-AzVMOperatingSystem -Windows -ComputerName 'myVm1' -Credential $cred |  Set-AzVMSourceImage -PublisherName 'MicrosoftWindowsServer' -Offer 'WindowsServer'  -Skus '2019-Datacenter' -Version latest | Add-AzVMNetworkInterface -Id $nicVM1.Id

$vm1 = New-AzVM -ResourceGroupName $rgName -Location $location -VM $vmConfig
$vmConfig = New-AzVMConfig -VMName 'myVm2' -VMSize 'Standard_DS1_V2' |  Set-AzVMOperatingSystem -Windows -ComputerName 'myVm2' -Credential $cred | Set-AzVMSourceImage -PublisherName 'MicrosoftSQLServer' -Offer 'SQL2019-WS2019' -Skus 'Web' -Version latest | Add-AzVMNetworkInterface -Id $nicVM2.Id
$vm2 = New-AzVM -ResourceGroupName $rgName -Location $location -VM $vmConfig




#Install IIS to view URL via Port 80 through Load Balancer Public IP

$ext = @{
    Publisher = 'Microsoft.Compute'
    ExtensionType = 'CustomScriptExtension'
    ExtensionName = 'IIS'
    ResourceGroupName = $rgName
    VMName = "myVm1"
    Location = $location
    TypeHandlerVersion = '1.8'
    SettingString = '{"commandToExecute":"powershell Add-WindowsFeature Web-Server; powershell Add-Content -Path \"C:\\inetpub\\wwwroot\\Default.htm\" -Value $($env:computername)"}'
}
Set-AzVMExtension @ext -AsJob
















