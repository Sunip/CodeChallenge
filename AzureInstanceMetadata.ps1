
# Get Credential
$cred = Get-Credential
$vmName = "metadatatest01" #Sample VM

#Script Block
$Script = {

    #Rest Method to get instance Metadata with no proxy being used . To Use Proxy remove No Proxy Parameter . 

    Invoke-RestMethod -Headers @{"Metadata"="true"} -Method GET -NoProxy -Uri "http://169.254.169.254/metadata/instance?api-version=2021-12-13" | ConvertTo-Json -Depth 99



}

#Establish PS Session to the Azure Instance and Use Invoke Command to run the results of script block from within the VM and display in JSON Format

$remoteSession = New-PSSession -ComputerName $vmName -Credential $cred 

Invoke-Command -Session $remoteSession -ScriptBlock $Script -ErrorAction Stop

