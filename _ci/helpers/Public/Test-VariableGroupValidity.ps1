function Test-VariableGroupValidity {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [Alias('VariableGroupDefinitionPath')]
        [ValidateNotNullOrEmpty()]
        [string]$DefinitionPath
    )
    process {
        $ErrorActionPreference = 'Stop'
        $definitionFileTest = Test-Path $DefinitionPath
        if ($false -eq $definitionFileTest) {
            throw ('Cannot find definition file {0}. Terminatting!' -f $DefinitionPath)
        }
        $definitionFiles = (Get-Item -Path $DefinitionPath)
        foreach ($file in $definitionFiles) {
            $jsonDefinition = ConvertFrom-Json (Get-Content -Path $file.FullName -Raw)
            if ($jsonDefinition.variableGroups.count -eq 0) {
                throw ('The variable group definition file {0} does not contain any variable group.' -f $file.Name)
            }
            # Test for duplicate variable groups
            foreach ($name in $jsonDefinition.variableGroups.name) {
                $nameCount = ($jsonDefinition.variableGroups | Where-Object { $_.Name -eq $name }).count
                if ($nameCount -gt 1) {
                    throw ('The variable group {0} in the definition file {1} appears more than once.' -f $name, $file.Name)
                }
            }
            foreach ($variableGroup in $jsonDefinition.variableGroups) {
                # Test project name reference
                $azDoProject = $env:BUILD_REPOSITORY_URI.split('/')[-3]
                if ($variableGroup.project -ne $azDoProject) {
                    throw ('The variable group {0} stored inside the definition file {1} is referencing the wrong project - [{2}].' -f $variableGroup.name, $file.Name, $variableGroup.project)
                }
                # Test variable count inside the variable group
                if ($variableGroup.variables.count -eq 0) {
                    throw ('The variable group {0} does not contain any variables.' -f $variableGroup.name)
                }
                $customObjectVariableProperties = $variableGroup.variables | Get-Member | Where-Object { $_.MemberType -like '*Property' }
                if ([string]::IsNullOrWhiteSpace($customObjectVariableProperties)) {
                    throw ('The variable group {0} does not contain any variables.' -f $variableGroup.name)
                }
                # Test variable definition, it has to include value, issecret and isreadonly properties
                $variableNames = ($variableGroup.variables | Get-Member | Where-Object { $_.MemberType -eq 'NoteProperty' }).Name
                foreach ($variable in $variableNames) {
                    $variableValueProperty = $variableGroup.variables.$variable | Get-Member | Where-Object { $_.Name -eq 'value' }
                    if ([string]::IsNullOrWhiteSpace($variableValueProperty)) {
                        throw ('The variable {0} in the variable group {1} does not contain value property.' -f $variable, $variableGroup.name)
                    }
                    $variableIsReadOnly = $variableGroup.variables.$variable | Get-Member | Where-Object { $_.Name -eq 'isReadOnly' }
                    if ([string]::IsNullOrWhiteSpace($variableIsReadOnly)) {
                        throw ('The variable {0} in the variable group {1} does not contain isReadOnly property.' -f $variable, $variableGroup.name)
                    }
                    $variableIsSecret = $variableGroup.variables.$variable | Get-Member | Where-Object { $_.Name -eq 'isSecret' }
                    if ([string]::IsNullOrWhiteSpace($variableIsSecret)) {
                        throw ('The variable {0} in the variable group {1} does not contain isSecret property.' -f $variable, $variableGroup.name)
                    }
                    $variableValue = $variableGroup.variables.$variable.value
                    $variableSecretValue = $variableGroup.variables.$variable.isSecret
                    if (($variableValue -notlike '@Microsoft.KeyVault(SecretUri=*') -and ($variableValue -like '*vault.azure.net/secrets*') -and ($variableSecretValue -eq $false)) {
                        throw ('The variable {0} referencing the key vault secret {1} is not configured to be the secret inside the {2} variable group.' -f $variable, $variableValue, $variableGroup.name)
                    }
                }
            }
        }
    }
}