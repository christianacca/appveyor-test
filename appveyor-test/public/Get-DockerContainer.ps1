function Get-DockerContainer
{
    <#
    .SYNOPSIS
    Return powershell objects describing container(s) on the docker host
    
    .DESCRIPTION
    Return powershell objects describing container(s) on the docker host
    
    .PARAMETER Name
    Filter container to return based on name
    
    .PARAMETER All
    Include stopped containers?
    
    .PARAMETER Inspect
    Return information about the container using `docker inspect`?
    
    .EXAMPLE
    Get-DockerContainer

    Description
    -----------
    Return running containers; see `docker container ls`

    .EXAMPLE
    Get-DockerContainer -All -Inspect

    Description
    -----------
    Return verbose information for both running and stopped containers; 
    see `docker container ls` and `docker container inspect`

    .EXAMPLE
    Get-DockerContainer my-container, my-container2

    Description
    -----------
    Return multiple containers by exact name match

    .EXAMPLE
    Get-DockerContainer 'my-*' -Inspect

    Description
    -----------
    Return verbose information for containers whose name matches a wildcard search

    .EXAMPLE
    Get-DockerContainer 'web*' -Inspect | select -PV container |
        ForEach-Object { $_.Mounts.Source } | 
        ForEach-Object { [PsCustomObject]@{ Name = $container.Name; MountPath = $_ } }

    Name                  MountPath
    ----                  ---------
    web-spa               C:\ProgramData\Docker\volumes\web-spa-iis-logs\_data
    web-spa               C:\ProgramData\Docker\volumes\web-spa-app-logs\_data
    web-tokensvr          C:\ProgramData\Docker\volumes\web-tokensvr-app-logs\_data

    Description
    -----------
    Return the local path(s) for volumes mounted into the containers whose name matches
    the wildcard search 'web*'
    
    .NOTES
    Alias 'gdc'

    #>
    [CmdletBinding(DefaultParameterSetName = 'List')]
    [OutputType('System.Management.Automation.PSCustomObject')]
    param (
        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'Name', Position = 0)]
        [SupportsWildcards()]
        [string[]]$Name,

        [Parameter(ParameterSetName = 'List')]
        [switch] $All,

        [switch] $Inspect
    )
    
    begin
    {
        Set-StrictMode -Version 'Latest'
        $callerEA = $ErrorActionPreference
        $ErrorActionPreference = 'Stop'
    }
    
    process
    {
        try
        {
            $candidateNames = if ($All -or $PSCmdlet.ParameterSetName -eq 'Name')
            {
                docker container ls -a --format '{{.Names}}'
            }
            else
            {
                docker container ls --format '{{.Names}}'
            }

            $matchedNames = switch ($PSCmdlet.ParameterSetName)
            {
                'List' 
                { 
                    $candidateNames
                }
                'Name' 
                { 
                    $Name | ForEach-Object {
                        $currentName = $_
                        $criteria = if ($currentName -match '\*')
                        {
                            { $_ -like $currentName }
                        }
                        else
                        {
                            { $_ -eq $currentName }
                        }
                        $candidateNames | Where-Object $criteria
                    } | Select-Object -Unique
                }
                Default 
                {
                    throw "ParameterSet '$PSCmdlet.ParameterSetName' not implemented"
                }
            }
            $containers = if ($Inspect)
            {
                $matchedNames |
                    ForEach-Object { [PsCustomObject](docker container inspect $_ | ConvertFrom-Json) } |
                    Select-Object -ExcludeProperty Name -Property @{n = 'Name'; e = { $_.Name.TrimStart('/')}}, *
            }
            else
            {
                docker container ls -a | ConvertFrom-Docker |
                    Where-Object { $_.Names -in $matchedNames } |
                    Select-Object -ExcludeProperty Names, Command -Property @{n = 'Name'; e = { $_.Names}}, *
            }
            $containers
        }
        catch
        {
            Write-Error -ErrorRecord $_ -EA $callerEA
        }
    }
}