[CmdletBinding()]
param (
    [Parameter(Mandatory)]
    [Alias('Organization')]
    [string]$DevOpsOrganization,

    [Parameter(Mandatory)]
    [Alias('Token', 'Pat')]
    [string]$AuthToken,

    [Parameter(Mandatory)]
    [Alias('VariableGroupDefinitionPath')]
    [string]$DefinitionPath
)
process {
    $ErrorActionPreference = 'Stop'
    $definitionFileTest = Test-Path $DefinitionPath
    if ($false -eq $definitionFileTest) {
        throw ('Cannot find definition file {0}. Terminatting!' -f $DefinitionPath)
    }
    $definitionFiles = (Get-Item -Path $DefinitionPath).FullName
    foreach ($file in $definitionFiles) {
        $jsonDefinition = ConvertFrom-Json (Get-Content -Path $file -Raw)
        if ($jsonDefinition.variableGroups.count -gt 0) {
            foreach ($variableGroup in $jsonDefinition.variableGroups) {
                $createVariableGroupSplat = @{
                    DevOpsOrganization = $DevOpsOrganization
                    AuthToken          = $AuthToken
                    Name               = $variableGroup.name
                    Project            = $variableGroup.project
                    Description        = $variableGroup.description
                    Variables          = $variableGroup.variables
                }
                $fetchVariableGroup = Get-AzDoVariableGroup -DevOpsOrganization $DevOpsOrganization -AuthToken $AuthToken -Project $variableGroup.project -Name $variableGroup.name
                if ([string]::IsNullOrWhiteSpace($fetchVariableGroup)) {
                    New-AzDoVariableGroup @createVariableGroupSplat
                }
                else {
                    write-host $variableGroup.name
                    New-AzDoVariableGroup @createVariableGroupSplat -Update:$true
                }
            }
        }
    }
}