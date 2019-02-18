class ValidationTarget {

    [string] $ComputerName = ''
    [object[]] $RequiredSoftware = @()
    [bool] $IsValid = $null
    [datetime] $ValidatedOn

    ValidationTarget( [string]$computerName ){
        $this.ComputerName = $computerName
    }

    [object[]] AddRequiredSoftware( [System.Object[]]$Software ){
        return $Software | ForEach-Object { $this.AddRequiredSoftware( $_ ) }
    }
    [object[]] AddRequiredSoftware( [System.Object]$Software ){

        if( -not $Software.MinVersion ){ $Software.MinVersion = [System.Version]::new() }
        if( -not $Software.SearchString ){ $Software.SearchString = $Software.Name }

        $getInstalledInstancesBlock = [scriptblock]{
            param ( [string]$ComputerName )

            $regKeys = @( 
                'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
                'HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'
            )
            $installed = @()
            
            Foreach ($key in $regKeys){
                try {
                    $installed +=  Invoke-Command -ComputerName $ComputerName -ScriptBlock {
                        Get-ItemProperty -Path $key | Where-Object { $_.DisplayName -like $this.SearchString } | Select-Object DisplayName,DisplayVersion
                    }
                }
                catch {}                
            }
            $this | Add-Member -MemberType NoteProperty -Name InstalledInstances -Value $installed
            $this | Add-Member -MemberType NoteProperty -Name Tested -Value (Get-Date)

            if( $this.InstalledInstances.DisplayVersion -ge $this.MinVersion ){ return $true }
            else { return $false }
        }

        $Software | Add-Member -MemberType NoteProperty -Name IsInstalled -Value $false
        $Software | Add-Member -MemberType ScriptMethod -Name GetInstallationStatus -Value $getInstalledInstancesBlock

        $this.RequiredSoftware += $Software
        return $Software
    }

    [object[]] AddRequiredSoftware( [string]$SoftwareName ){
        return $this.AddRequiredSoftware( $SoftwareName, $SoftwareName)
    }
    
    [object[]] AddRequiredSoftware( [string]$SoftwareName, [string]$SearchString ){
        return $this.AddRequiredSoftware( $SoftwareName, $SearchString, '0.0.0' )
    }

    [object[]] AddRequiredSoftware( [string]$SoftwareName, [string]$SearchString, [string]$MinVersion ){
        $swObj = [PSCustomObject]@{
            Name = $SoftwareName;
            SearchString = $SearchString;
            MinVersion = [system.version]::new($MinVersion)
        }
        return $this.AddRequiredSoftware($swObj)
    }
    
    [bool] ValidateSoftware(){

        Foreach( $software in $this.RequiredSoftware ){
            Invoke-Command -ComputerName $this.ComputerName -ScriptBlock $software.GetInstallationStatus( $this.ComputerName )
        }

        $successCount = $this.RequiredSoftware.IsInstalled | Measure-Object -Sum 
        $testCount = $this.RequiredSoftware.IsInstalled | Measure-Object -Count
        $testPassed = $successCount -eq $testCount

        $this.ValidatedOn = Get-Date
        $this.IsValid = $testPassed
        return $testPassed
    }

}