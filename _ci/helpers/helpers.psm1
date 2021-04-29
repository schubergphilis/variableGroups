# Test paths to the public, private and classes folder, dot source files from found directories
if ($true -eq (Test-Path -Path (Join-Path -Path $PSScriptRoot -ChildPath 'Public'))) {
    $public  = @(Get-ChildItem -Path (Join-Path -Path $PSScriptRoot -ChildPath 'Public/*.ps1')  -Recurse -ErrorAction Stop)
}
if ($true -eq (Test-Path -Path (Join-Path -Path $PSScriptRoot -ChildPath 'Private'))) {
    $private = @(Get-ChildItem -Path (Join-Path -Path $PSScriptRoot -ChildPath 'Private/*.ps1') -Recurse -ErrorAction Stop)
}
if ($true -eq (Test-Path -Path (Join-Path -Path $PSScriptRoot -ChildPath 'Classes'))) {
    $classes = @(Get-ChildItem -Path (Join-Path -Path $PSScriptRoot -ChildPath 'Classes/*class.ps1') -Recurse -ErrorAction Stop)
}
# Source classes, if any files are found
if ($classes) {
    foreach ($import in $classes) {
        try {
            . $import.FullName
        }
        catch {
            throw "Unable to dot source [$($import.FullName)]"
        }
    }
}
# Source private functions, if any files are found
if ($private) {
    foreach ($import in $private) {
        try {
            . $import.FullName
        }
        catch {
            throw "Unable to dot source [$($import.FullName)]"
        }
    }
}
# Source public functions, if any files are found
if ($public) {
    foreach ($import in $public) {
        try {
            . $import.FullName
        }
        catch {
            throw "Unable to dot source [$($import.FullName)]"
        }
    }
    # Export public functions
    Export-ModuleMember -Function $public.Basename
}