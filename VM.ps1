

#Create NIC for VM's

function createnic {

$global:nicVM1 = New-AzNetworkInterface -ResourceGroupName $rgName -Location $location -Name 'nicVM1' -PublicIpAddress $pip1 -NetworkSecurityGroup $nsg1 -Subnet $frontendsubnet -LoadBalancerBackendAddressPool $bepool

$global:nicVM2 = New-AzNetworkInterface -ResourceGroupName $rgName -Location $location -Name 'nicVM2' -PublicIpAddress $pip2 -NetworkSecurityGroup $nsg2 -Subnet $backendsubnet
}

#Create Web and DB VM
function createVM {
$cred = Get-Credential

$global:vmConfig = New-AzVMConfig -VMName 'myVm1' -VMSize 'Standard_DS1_v2' |  Set-AzVMOperatingSystem -Windows -ComputerName 'myVm1' -Credential $cred |  Set-AzVMSourceImage -PublisherName 'MicrosoftWindowsServer' -Offer 'WindowsServer'  -Skus '2019-Datacenter' -Version latest | Add-AzVMNetworkInterface -Id $nicVM1.Id

$global:vm1 = New-AzVM -ResourceGroupName $rgName -Location $location -VM $vmConfig
$global:vmConfig = New-AzVMConfig -VMName 'myVm2' -VMSize 'Standard_DS1_V2' |  Set-AzVMOperatingSystem -Windows -ComputerName 'myVm2' -Credential $cred | Set-AzVMSourceImage -PublisherName 'MicrosoftSQLServer' -Offer 'SQL2019-WS2019' -Skus 'Web' -Version latest | Add-AzVMNetworkInterface -Id $nicVM2.Id
$global:vm2 = New-AzVM -ResourceGroupName $rgName -Location $location -VM $vmConfig

}


#Install IIS to view URL via Port 80 through Load Balancer Public IP

function installIIS {

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

}