#Get Subnet Details

function fetchsubnet {

$global:frontendsubnet = Get-AzVirtualNetworkSubnetConfig -Name "Subnet1" -VirtualNetwork $vnet
$global:backendsubnet = Get-AzVirtualNetworkSubnetConfig -Name "Subnet2" -VirtualNetwork $vnet

}

#Create Network Security Rules for Web VM to allow RDP and Internet Access to web URL

function creatensgforwebvm {
$global:rule1 = New-AzNetworkSecurityRuleConfig -Name 'AllowAccesstoFrontEndFromInternet' -Description 'Allow Access to Front End From Internet' -Access Allow -Protocol Tcp -Direction Inbound -Priority 100 -SourceAddressPrefix Internet -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 80

$global:rule2 = New-AzNetworkSecurityRuleConfig -Name 'AllowSecureAccesstoFrontEndFromInternet' -Description 'Allow Secure Access to Front End From Internet' -Access Allow -Protocol Tcp -Direction Inbound -Priority 200 -SourceAddressPrefix Internet -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 443

$global:rule3 = New-AzNetworkSecurityRuleConfig -Name 'AllowAccesstoFrontEndForRDP' -Description 'Allow Access to Front End For RDP' -Access Allow -Protocol Tcp -Direction Inbound -Priority 300 -SourceAddressPrefix Internet -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 3389


#Create NSG for Web VM and associate rules above

New-AzNetworkSecurityGroup -ResourceGroupName $rgName -Location $location -Name 'nsg1' -SecurityRules $rule1,$rule2,$rule3

$global:nsg1 = Get-AzNetworkSecurityGroup -Name "nsg1"

#Associate NSG Web VM to Subnet 1 

Set-AzVirtualNetworkSubnetConfig -Name "Subnet1" -VirtualNetwork $vnet -NetworkSecurityGroup $nsg1 -AddressPrefix '10.0.1.0/26'

}

#Create Rule$nic between Web SUbnet and DB Subnet and Internet to DB Server RDP

function creatensgfordbvm {

$global:rule4= New-AzNetworkSecurityRuleConfig -Name 'AllowAccesstoDBfromWeb' -Description 'Allow Access to DB from Web' -Access Allow -Protocol Tcp -Direction Inbound -Priority 100 -SourceAddressPrefix '10.0.1.0/26' -SourcePortRange * -DestinationAddressPrefix *  -DestinationPortRange 1433
$global:rule5 = New-AzNetworkSecurityRuleConfig -Name 'AllowAccesstoBackendEndForRDP' -Description 'Allow Access to Backend End For RDP' -Access Allow -Protocol Tcp -Direction Inbound -Priority 200 -SourceAddressPrefix Internet -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 3389

#Create NSG for DB VM and associate rules above
$global:nsg2 = New-AzNetworkSecurityGroup -ResourceGroupName $rgName -Location $location -Name 'nsg2' -SecurityRules $rule4,$rule5

Set-AzNetworkSecurityGroup -NetworkSecurityGroup $nsg2 

#Attach nsg DB VM to backend subnet

Set-AzVirtualNetworkSubnetConfig -VirtualNetwork $vnet -Name 'Subnet2' -AddressPrefix '10.0.2.0/26' -NetworkSecurityGroup $nsg2

}