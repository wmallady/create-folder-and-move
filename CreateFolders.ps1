
Enable-PSRemoting -Force
# enables creation of folders on other's computers 

#############################################

$date = Get-Date -UFormat "%m/%d/%Y %R" 
# date variable for log file 
$dateDay = Get-Date -Uformat "%d"
# grabs only the day from date 

$logFile = '\\some\log\path' + $dateDay + '.txt'
# Path to Log Folder 

$whoRan = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
# variable containing who ran the script 

$userComps = @(Import-CSV "\\some\path\userComps.csv")
# imports csv file userComps and assigns it to array 

$folderList =@(Import-CSV "\\some\path\folderList.csv")
# imports csv file folderList and assigns it to array

########## Delete Old Log Files ##############

$CurrentDate = Get-Date
$DatetoDelete = $CurrentDate.AddDays(-27)
# number of days to hold the log files for. 27 because that is the largest amount we can do without causing issues in Feb. 


Get-ChildItem $logFile -Recurse  | Where-Object { $_.LastWriteTime -lt $DatetoDelete } | Remove-Item -force -recurse
# grab $logfile recrusively and check its date. If it is older than 27 days, overwrites it with new log file. 

################################################


foreach ($user in $userComps) #grabs each user in array 
{   
    $friendlyName = $user.computer.Substring(2)
    #chops '\\' from computer name for Invoke-Command 

    foreach($folder in $folderList) 
    # tries to make each folder in array for each user in array 

    {

        $networkPath = $user.computer + '\c$\network\' + $folder.path
        #path to network folder

        if(!(Test-Path $networkPath)) #tests if folder is there. 
            
        # If no, makes the folder. 
        {
            New-Item -Path $networkPath -ItemType "directory"
            Write-host "$whoRan created file $($folder.path) to $networkPath at $date" -ForegroundColor green
            Write-Output "$whoRan created file $($folder.path) to $networkPath at $date" >> $logFile
        }
        
        # If yes, sends error message.
        else
        {
            Write-Host  "The file $($folder.path) already exists on $($user.name)'s computer." -ForegroundColor red
            Write-Output "$whoRan failed to make file $($folder.path) to $($user.computer) at $date because file already exists" >> $logFile
            # Gives an error in console and then writes failure to log
        }
        
        # This code block creates shortcuts on a users public desktop  
        $localFilePath = "C:\some\local\" + $folder.path 
        #creates local folder path on users computer 
        $shortcutLocation = $user.computer + "\c$\Users\Public\Desktop\" + $folder.path + ".lnk" 
        # creates the .lnk to local folders just created 
        $WScriptShell = New-Object -ComObject WScript.Shell 
        # instantiate new com object in order to create shortcut 
        $Shortcut = $WScriptShell.CreateShortcut($shortcutLocation) 
        # creates new folder at specified location 
        $Shortcut.TargetPath = $localFilePath
        # points the shortcut to the folder
        $Shortcut.Save()
    
    }
    
    $command = 
    {
        $shareFolder = 'NetworkShare'
        #name of the network share that you want to create. No need for '\'.

        If (!(Get-SmbShare -Name $shareFolder -ErrorAction SilentlyContinue)) 
            {
                write-host "Creating share: " $shareFolder -ForegroundColor green
                # out to console confirming that sharefolder is being created 
                $sharePath = "C:\local\path"
                # points to local folder (content you want shared)
                New-SmbShare -Name $shareFolder -Path $sharePath -FullAccess Everyone 
                # create linked share folder where -$shareFolder is the name of the network folder and $sharePath is the local content the link points to.

                Write-Output "$whoRan created $shareFolder on $date" >> $logFile
                # log creation of share folder 
            } 
        else 
            {
                write-host "The share already exists: " $shareFolder -ForegroundColor Red
                # output to console an error message in red if it fails
                Write-Output "$whoRan failed to create $sharefolder on $date" >> $logFile
            }
    }
    Invoke-Command -ComputerName $friendlyName -scriptblock $command
    # invokes command to create folder on network at \\(user address)\path
}
