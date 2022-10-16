function NestedObject($object,[string[]]$key)   ##Function to Display Value depending on key

 {
    $a=$key.count
    $b=$key[0]
    if ($a -eq 1)

    {
        Write-Host $object.$b

    }

    else {

        
        
        NestedObject -object $object.$b -key ($key[1..($key.count-1)])      ##Call the function recusrively within and remove the 1st element untill we are left with only 1 element in the array
    }



 }


 # Get the JSON File as input and convert into Powershell Object
$object = Get-Content "C:\Users\srija\OneDrive\Desktop\Sunip.json.txt" | Out-String | ConvertFrom-Json

#Call the Function
NestedObject -object $object -key "aws/region/country".Split("/")

