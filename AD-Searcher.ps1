# Create an array to store all computer objects
$AllComputers = @()

# Get all domains in the forest
$Forest = [System.DirectoryServices.ActiveDirectory.Forest]::GetCurrentForest()
$Domains = $Forest.Domains
$DomainCount = $Domains.Count

Write-Host "Starting scan of $DomainCount domains..." -ForegroundColor Green

$currentDomainIndex = 0
foreach ($Domain in $Domains) {
    $currentDomainIndex++
    $domainProgress = ($currentDomainIndex / $DomainCount) * 100
    
    Write-Progress -Activity "Scanning Domains" -Status "Processing $($Domain.Name)" `
        -PercentComplete $domainProgress -Id 1
    
    # Create domain context
    $Context = New-Object System.DirectoryServices.ActiveDirectory.DirectoryContext("Domain", $Domain.Name)
    $CurrentDomain = [System.DirectoryServices.ActiveDirectory.Domain]::GetDomain($Context)
    
    # Search for Windows computers
    $Searcher = New-Object System.DirectoryServices.DirectorySearcher
    $Searcher.SearchRoot = $CurrentDomain.GetDirectoryEntry()
    $Searcher.Filter = "(&(objectCategory=computer)(operatingSystem=*windows*))"
    $Searcher.PageSize = 1000
    
    # Add the properties we want to retrieve
    $Searcher.PropertiesToLoad.AddRange(@(
        "name",
        "operatingSystem",
        "lastLogonTimestamp",
        "distinguishedName"
    ))
    
    try {
        $Results = $Searcher.FindAll()
        $computerCount = $Results.Count
        $currentComputer = 0
        
        foreach ($Computer in $Results) {
            $currentComputer++
            $computerProgress = ($currentComputer / $computerCount) * 100
            
            # Update progress bar for computers within domain
            Write-Progress -Activity "Processing Computers in $($Domain.Name)" `
                -Status "Computer $currentComputer of $computerCount" `
                -PercentComplete $computerProgress -Id 2 -ParentId 1
            
            # Convert lastLogonTimestamp if it exists and is valid
            $LastLogon = $null
            if ($Computer.Properties["lastLogonTimestamp"]) {
                try {
                    $timestamp = $Computer.Properties["lastLogonTimestamp"][0]
                    if ($timestamp -match '^\d+
            
            # Create computer object and add to array
            $ComputerObj = [PSCustomObject]@{
                ComputerName = $Computer.Properties["name"][0]
                OperatingSystem = $Computer.Properties["operatingSystem"][0]
                Domain = $Domain.Name
                LastLogon = $LastLogon
                DistinguishedName = $Computer.Properties["distinguishedName"][0]
            }
            
            # Add to array
            $AllComputers += $ComputerObj
        }
        
        Write-Host "Found $($Results.Count) computers in $($Domain.Name)" -ForegroundColor Yellow
    }
    catch {
        Write-Warning "Error scanning domain $($Domain.Name): $($_.Exception.Message)"
    }
}

# Clear progress bars
Write-Progress -Activity "Scanning Domains" -Id 1 -Completed
Write-Progress -Activity "Processing Computers" -Id 2 -Completed

# Export to CSV for comparison with SCOM
$timestamp = Get-Date -Format 'yyyy-MM-dd_HH-mm'
$exportPath = "AD_Computers_$timestamp.csv"
$AllComputers | Export-Csv -Path $exportPath -NoTypeInformation

Write-Host "`nInventory Complete!" -ForegroundColor Green
Write-Host "Total computers found across all domains: $($AllComputers.Count)" -ForegroundColor Green
Write-Host "Results exported to: $exportPath" -ForegroundColor Green) {  # Verify it contains only digits
                        $LastLogon = [DateTime]::FromFileTime([Int64]::Parse($timestamp))
                    }
                }
                catch {
                    Write-Verbose "Could not parse lastLogonTimestamp for computer $($Computer.Properties["name"][0]): $timestamp"
                }
            
            # Create computer object and add to array
            $ComputerObj = [PSCustomObject]@{
                ComputerName = $Computer.Properties["name"][0]
                OperatingSystem = $Computer.Properties["operatingSystem"][0]
                Domain = $Domain.Name
                LastLogon = $LastLogon
                DistinguishedName = $Computer.Properties["distinguishedName"][0]
            }
            
            # Add to array
            $AllComputers += $ComputerObj
        }
        
        Write-Host "Found $($Results.Count) computers in $($Domain.Name)" -ForegroundColor Yellow
    }
    catch {
        Write-Warning "Error scanning domain $($Domain.Name): $($_.Exception.Message)"
    }
}

# Clear progress bars
Write-Progress -Activity "Scanning Domains" -Id 1 -Completed
Write-Progress -Activity "Processing Computers" -Id 2 -Completed

# Export to CSV for comparison with SCOM
$timestamp = Get-Date -Format 'yyyy-MM-dd_HH-mm'
$exportPath = "AD_Computers_$timestamp.csv"
$AllComputers | Export-Csv -Path $exportPath -NoTypeInformation

Write-Host "`nInventory Complete!" -ForegroundColor Green
Write-Host "Total computers found across all domains: $($AllComputers.Count)" -ForegroundColor Green
Write-Host "Results exported to: $exportPath" -ForegroundColor Green
