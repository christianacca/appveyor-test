Describe 'Get-DockerContainer' -Tags Build {

    BeforeAll {
        Unload-SUT
        Import-Module ($global:SUTPath)
    }

    AfterAll {
        Unload-SUT
    }

    It 'Alias' -Skip {
        & {gdc -EA Stop | Out-Null; $true} | Should -Be $true
    }
    
    It 'List' {
        & {Get-DockerContainer -EA Stop | Out-Null; $true} | Should -Be $true
    }
    
    It 'List -All' {
        & {Get-DockerContainer -All -EA Stop | Out-Null; $true} | Should -Be $true
    }
    
    It 'List -Inspect' {
        & {Get-DockerContainer -Inspect -EA Stop | Out-Null; $true} | Should -Be $true
    }
    
    It 'List -All -Inspect' {
        & {Get-DockerContainer -All -Inspect -EA Stop | Out-Null; $true} | Should -Be $true
    }
    
    It '-All cannot be used with -Name' {
        {Get-DockerContainer -All -Name 'some-container' -EA Stop} | Should throw
    }

    It '-Name' {
        & {Get-DockerContainer -Name 'some-container' -EA Stop | Out-Null; $true} | Should -Be $true
    }
    
    It '-Name (by position)' {
        & {Get-DockerContainer 'some-container' -EA Stop | Out-Null; $true} | Should -Be $true
    }

    It '-Name (by pipeline value)' {
        & { @('some-container') | Get-DockerContainer -EA Stop | Out-Null; $true} | Should -Be $true
    }
    
    It '-Name -Inspect' {
        & {Get-DockerContainer 'some-container' -Inspect -EA Stop | Out-Null; $true} | Should -Be $true
    }
}

