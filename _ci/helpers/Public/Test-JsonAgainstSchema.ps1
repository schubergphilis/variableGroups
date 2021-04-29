function Test-JsonAgainstSchema {
    [cmdletbinding()]
    [OutputType([bool])]
    param (
        [Parameter(Mandatory, Position = 0)]
        [ValidatePattern('.*\.json$')]
        [string]$JsonFile
    )
    process {
        $ErrorActionPreference = 'Stop'
        $ProgressPreference = 'SilentlyContinue'
        if ($false -eq (Test-Path -Path $JsonFile)) {
            Write-Warning ('The path [{0}] does not exist, or the process cannot access it.' -f $JsonFile)
            return($false)
        }
        $rawJson = Get-Content -Path $JsonFile -Raw
        $jsonObject = ConvertFrom-Json $rawJson -Depth 100
        if ($false -eq ($jsonObject.psobject.properties.Name -contains '$schema')) {
            Write-Warning ('The JSON file [{0}] does not contain the valid $schema property.' -f $JsonFile)
            return($false)
        }
        try {
            $schemaUri = $jsonObject.'$schema'
            $webObject = Invoke-WebRequest -Uri $schemaUri
            $jsonSchema = $webObject.Content
            if ($false -eq (Test-Json -Json $jsonSchema)) {
                Write-Warning ('Defined schema at the location [{0}] does not have a valid JSON structure.' -f $schemaUri)
                return($false)
            }
            [bool]$jsonSchemaTest = Test-Json -Json $rawJson -Schema $jsonSchema -ErrorAction 'SilentlyContinue'
            if ($false -eq $jsonSchemaTest) {
                $errorMessage = [system.string]::join([System.Environment]::NewLine, [System.Environment]::NewLine, $Error[0].errordetails.message)
                Write-Warning ('The file [{0}] cannot be validated against the JSON schema [{1}]. The failure message is: {2}' -f $JsonFile, $schemaUri, $errorMessage)
                return($false)
            }
        }
        catch {
            Write-Error ('Problem with fetching the schema content from the web, server reported a following message: {0}' -f $Error[0].errordetails.message)
        }
        return($true)
    }
}