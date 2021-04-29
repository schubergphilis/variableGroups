function Switch-AzDoVariableSecret {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [Alias('VariableGroupDefinitionPath')]
        [ValidateNotNullOrEmpty()]
        [string]$DefinitionPath
    )
    process {
        $ErrorActionPreference = 'Stop'
        Set-StrictMode -Off
        Import-Module 'Az.KeyVault'
        $definitionFileTest = Test-Path $DefinitionPath
        if ($false -eq $definitionFileTest) {
            throw ('Cannot find definition file {0}. Terminatting!' -f $DefinitionPath)
        }
        $definitionFiles = (Get-Item -Path $DefinitionPath)
        foreach ($file in $definitionFiles) {
            $jsonDefinition = ConvertFrom-Json (Get-Content -Path $file.FullName -Raw)
            foreach ($variableGroup in $jsonDefinition.variableGroups) {
                $variableNames = ($variableGroup.variables | Get-Member | Where-Object { $_.MemberType -eq 'NoteProperty' }).Name
                foreach ($variable in $variableNames) {
                    if (($variableGroup.variables.$variable.value -like '*vault.azure.net/secrets*') -and ($variableGroup.variables.$variable.value  -notlike '@Microsoft.KeyVault(SecretUri=*')) {
                        $variableValue = $variableGroup.variables.$variable.value
                        $secretUriSplit = $variableValue.Split('/')
                        $vaultName = $secretUriSplit[2].Replace('.vault.azure.net', '')
                        if ($secretUriSplit.count -eq 5) {
                            $secretName = $secretUriSplit[-1]
                            try {
                                Write-Host ('Trying to fetch the secret {0} from the KeyVault {1}' -f $secretName, $vaultName) -ForegroundColor Green
                                $secretValue = (Get-AzKeyVaultSecret -VaultName $vaultName -Name $secretName).SecretValueText
                                $variableGroup.variables.$variable.value = $secretValue
                            }
                            catch [Microsoft.Azure.KeyVault.Models.KeyVaultErrorException] {
                                throw 'Cannot fetch required Key Vault secret(s).'
                            }
                        }
                        if ($secretUriSplit.count -eq 6) {
                            $secretName = $secretUriSplit[-2]
                            $secretVersion = $secretUriSplit[-1]
                            try {
                                Write-Host ('Trying to fetch the secret {0} version {1} from the KeyVault {2}' -f $secretName, $secretVersion, $vaultName) -ForegroundColor Green
                                $secretValue = (Get-AzKeyVaultSecret -VaultName $vaultName -Name $secretName -Version $secretVersion).SecretValueText
                                $variableGroup.variables.$variable.value = $secretValue
                            }
                            catch [Microsoft.Azure.KeyVault.Models.KeyVaultErrorException] {
                                throw 'Cannot fetch required Key Vault secret(s).'
                            }
                        }
                    }
                }
            }
        }
        Write-Verbose 'Writing secrets inside the definition file' -Verbose
        [void](ConvertTo-Json $jsonDefinition -Depth 100 | Out-File $DefinitionPath -Force)
    }
}