function New-AzDoVariableGroup {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [Alias('Organization')]
        [string]$DevOpsOrganization,

        [Parameter(Mandatory)]
        [Alias('Token', 'Pat')]
        [string]$AuthToken,

        [Parameter(Mandatory)]
        [string]$Project,

        [Parameter(Mandatory)]
        [Alias('VariableGroup')]
        [string]$Name,

        [Parameter(Mandatory)]
        [string]$Description,

        [Parameter(Mandatory)]
        [object]$Variables,

        [switch]$Update

    )
    process {
        $ErrorActionPreference = 'Stop'
        $authorizationHeader = Initialize-Authentication $AuthToken
        $baseUri = 'https://dev.azure.com/{0}' -f $DevOpsOrganization
        $apiVersion = 'api-version=6.0-preview.2'
        $body = @{
            name                           = $Name
            description                    = $Description
            variableGroupProjectReferences = @(
                @{
                    name             = $Name
                    description      = $Description
                    projectReference = @{
                        name = $Project
                    }
                }
            )
            variables = $Variables
        }
        $restSplat = @{
            Uri         = ('{0}/_apis/distributedtask/variablegroups?{1}' -f $baseUri, $apiVersion)
            Body        = (ConvertTo-Json $body -Depth 100)
            Method      = 'Post'
            Headers     = $authorizationHeader
            ContentType = 'application/json'
        }
        if ($Update.IsPresent) {
            $fetchVariableGroup =  Get-AzDoVariableGroup -DevOpsOrganization $DevOpsOrganization -AuthToken $AuthToken -Project $Project -Name $Name
            $restSplat.Uri = ('{0}/_apis/distributedtask/variablegroups/{1}?{2}' -f $baseUri, $fetchVariableGroup.id, $apiVersion)
            $restSplat.Method = 'Put'
        }
        Invoke-RestMethod @restSplat
    }
}