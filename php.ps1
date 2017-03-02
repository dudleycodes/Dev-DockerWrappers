clear

$settingDefaultPage = "";


Function pause ($message)
{
    # Check if running Powershell ISE
    if ($psISE)
    {
        Add-Type -AssemblyName System.Windows.Forms
        [System.Windows.Forms.MessageBox]::Show("$message")
    }
    else
    {
        Write-Host "$message" -ForegroundColor Yellow
        $x = $host.ui.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    }
}


$sourceDir = (Get-Item -Path ".\" -Verbose).FullName + [IO.Path]::DirectorySeparatorChar + "src";
$sourceDrive = (Get-Item -Path $sourceDir).PSDrive.Root


##############################################################
## Verify Docker is Installed and Running
##############################################################
    $output = docker info 2>&1

    if(!$?)
    {
        $output = docker 2>&1
        if (!$?) {
            Write-Host "Docker must be installed and running!"
        }
        else
        {
            Write-Host "Docker must be running!"
        }
        
        exit;
    }

##############################################################
## Verify source drive is shared with current Windows user
## (this is how the Docker VM accesses it to mount a volume)
##############################################################
    Write-Host "";
    Write-Host "Checking that the appropriate drive is shared!"; 
    
    #This isn't a gaurnteed check; still need to verify current user can access the share
    
    if ((Get-WmiObject -Class Win32_Share | Where {$_.Path -eq "$sourceDrive"} | Where {$_.Type -eq 0 } | Measure).Count -lt 1) {
        Write-Host "Drive containing the repository ($sourceDrive) must be shared with the current user!";
        exit;
    }

##############################################################
## Launch the container
##############################################################
    if ([IO.Path]::DirectorySeparatorChar -ne "/") {
        $volDir = $sourceDir.Replace([IO.Path]::DirectorySeparatorChar, "/");
    } else {
        $volDir = $sourceDir;
    }

    $containerName = (Get-Item -Path ".\" -Verbose).Name + "-" + (Get-Date).Ticks
    $containerPort = 8080;

    Write-Host "Starting Container: '$containerName'"
    
    $command = "docker run -d --name $containerName -p $containerPort" + ":80 -v " + '"' + "$sourceDir" + ':' + '/var/www/html/' + '" ' + "php:5-apache"    

    Invoke-Expression $command | Out-Null
    
    if(!$?)
    {
        Write-Host "Something went wrong"
        exit;
    } 

    ## Open in web browser
    $command = "start http://localhost:" + $containerPort + "/" + $settingDefaultPage;
    Invoke-Expression $command | Out-Null


    pause "Press any key to stop and remove $containerName" | Out-Null


##############################################################
## Stop the container
##############################################################

    Write-Host "Stopping container: '$containerName'"

    $command = "docker stop $containerName"
    Invoke-Expression $command | Out-Null

##############################################################
## Delete the container
##############################################################

    Write-Host "Deleting container: '$containerName'"

    $command = "docker rm $containerName"
    Invoke-Expression $command | Out-Null


Write-Host "============="
Write-Host ""
