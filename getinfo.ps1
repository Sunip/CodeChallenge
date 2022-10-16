function getinfo {

Connect-AzAccount

#Find RG and Sub Details

Get-AzSubscription

$rg = Get-AzResourceGroup

$global:rgName = $rg.ResourceGroupName
$global:location = $rg.location



}