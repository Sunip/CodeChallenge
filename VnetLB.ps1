#Create VNET and Subnets' for both VM's

function createvnet  {

$global:subnet1 = New-AzVirtualNetworkSubnetConfig -Name "Subnet1" -AddressPrefix '10.0.1.0/26'

$global:subnet2 = New-AzVirtualNetworkSubnetConfig -Name "Subnet2" -AddressPrefix '10.0.2.0/26'

$global:vnet = New-AzVirtualNetwork -Name "myvnet" -ResourceGroupName "$rgName" -Location $location -AddressPrefix "10.0.0.0/16" -Subnet $subnet1,$subnet2

}

#Create Public Ip's and Front End Load Balancer Config

function LoadBalancer {

$global:pip1 = New-AzPublicIpAddress -Name "pip1" -ResourceGroupName "$rgName" -Location $location -AllocationMethod Static -Sku Standard

$global:pip2 = New-AzPublicIpAddress -Name "pip2" -ResourceGroupName "$rgName" -Location $location -AllocationMethod Static -Sku Standard

$global:pip3 = New-AzPublicIpAddress -Name "pip3" -ResourceGroupName "$rgName" -Location $location -AllocationMethod Static -Sku Standard

$a = Get-AzPublicIpAddress -Name "pip3" -ResourceGroupName "$rgName"

$global:Id = $a.Id

$global:frontendip = New-AzLoadBalancerFrontendIpConfig -Name "myFrontEnd" -PublicIpAddressId "$Id"
$global:backendpool = New-AzLoadBalancerBackendAddressPoolConfig -Name 'myBackEndPool'

$global:healthprobe = New-AzLoadBalancerProbeConfig -Name 'myHealthProbe' -Protocol 'tcp' -Port '80' -IntervalInSeconds '60' -ProbeCount '5' 

$global:rule = New-AzLoadBalancerRuleConfig -Name 'myHTTPRule' -Protocol 'tcp' -FrontendPort '80' -BackendPort '80' -IdleTimeoutInMinutes '15' -FrontendIpConfiguration $frontendip -BackendAddressPool $backendpool -LoadDistribution Default


New-AzLoadBalancer -ResourceGroupName $rgName -Name 'myLoadBalancer' -Location $location -Sku 'Standard' -FrontendIpConfiguration $frontendip -BackendAddressPool $backendpool -LoadBalancingRule $rule -Probe $healthprobe

 }