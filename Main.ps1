<#
Script to Create a 3 Tier Environment. It will consist of a Front end Load Balancer , which will communicate with a IIS Server over Port 80 which will inturn 
communicate with a DB Server over port 1433
#>

. "C:\Users\srija\OneDrive\Documents\getinfo.ps1"
getinfo

. "C:\Users\srija\OneDrive\Documents\VnetLB.ps1"
createvnet
LoadBalancer


. "C:\Users\srija\OneDrive\Documents\nsg.ps1"
fetchsubnet
creatensgforwebvm
creatensgfordbvm

. "C:\Users\srija\OneDrive\Documents\VM.ps1"
createnic
createVM
installIIS