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
    $Searcher.Filter = "(&(objectCategory=computer)(operatingSystem=*windows*)(lastLogonTimestamp>=*))"
    $Searcher.PropertiesToLoad.Add("name")
    $Searcher.PropertiesToLoad.Add("operatingSystem")
    $Searcher.PropertiesToLoad.Add("lastLogonTimestamp")
    
    try {
        $Results = $Searcher.FindAll()
        foreach ($Computer in $Results) {
            $LastLogon = [DateTime]::FromFileTime([Int64]::Parse($Computer.Properties["lastLogonTimestamp"][0]))
            
            [PSCustomObject]@{
                ComputerName = $Computer.Properties["name"][0]
                OperatingSystem = $Computer.Properties["operatingSystem"][0]
                Domain = $Domain.Name
                LastLogon = $LastLogon
            }
        }
    }
    catch {
        Write-Warning "Error scanning domain $($Domain.Name): $($_.Exception.Message)"
    }
    finally {
        if ($Results) { $Results.Dispose() }
        $Searcher.Dispose()
    }
}
