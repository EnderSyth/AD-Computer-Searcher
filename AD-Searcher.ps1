# Create an array to store all computer objects
$AllComputers = @()

# Get all domains in the forest
$Forest = [System.DirectoryServices.ActiveDirectory.Forest]::GetCurrentForest()
$Domains = $Forest.Domains

foreach ($Domain in $Domains) {
    Write-Host "Scanning domain: $($Domain.Name)" -ForegroundColor Green
    
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
        "distinguishedName",
        "enabled"
    ))
    
    try {
        $Results = $Searcher.FindAll()
        
        foreach ($Computer in $Results) {
            # Convert lastLogonTimestamp if it exists
            $LastLogon = if ($Computer.Properties["lastLogonTimestamp"]) {
                [DateTime]::FromFileTime([Int64]::Parse($Computer.Properties["lastLogonTimestamp"][0]))
            } else { $null }
            
            # Create computer object and add to array
            $ComputerObj = [PSCustomObject]@{
                ComputerName = $Computer.Properties["name"][0]
                OperatingSystem = $Computer.Properties["operatingSystem"][0]
                Domain = $Domain.Name
                LastLogon = $LastLogon
                DistinguishedName = $Computer.Properties["distinguishedName"][0]
            }
            
            # Output to pipeline
            Write-Output $ComputerObj
            
            # Add to array
            $AllComputers += $ComputerObj
        }
        
        Write-Host "Found $($Results.Count) computers in $($Domain.Name)" -ForegroundColor Yellow
    }
    catch {
        Write-Warning "Error scanning domain $($Domain.Name): $($_.Exception.Message)"
    }
}

# Export to CSV for comparison with SCOM
$AllComputers | Export-Csv -Path "AD_Computers_$(Get-Date -Format 'yyyy-MM-dd').csv" -NoTypeInformation

Write-Host "Total computers found across all domains: $($AllComputers.Count)" -ForegroundColor Green
