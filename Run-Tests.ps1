function Initialize-Tests {    
    Param (

        [Parameter(Mandatory = $true)]
        [string[]] $ComputerName,
        [Parameter(Mandatory = $true)]
        [object[]] $RequiredSoftware
    )      
    
    [ValidationTarget[]]$TestTargets = @()
    Foreach ($Computer in $ComputerNames) {
        $TestTargets += [ValidationTarget]::new( $Computer )
    }

    $TestTargets.AddRequiredSoftware($RequiredSoftware)
    return $TestTargets

}

. .\ValidationTarget.class.ps1

$ComputerNames = Get-Content .\ComputerList.txt
$RequiredSoftware = Get-Content .\RequiredSoftware.json | ConvertFrom-Json

$TestTargets = Initialize-Tests -ComputerName $ComputerNames -RequiredSoftware $RequiredSoftware
$TestTargets.ValidateSoftware()
