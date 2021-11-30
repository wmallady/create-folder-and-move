
# DATE & TIME #
$date = Get-Date -UFormat "%m/%d/%Y %R"
# date format MM-DD-YYYY 24:00
$dateDay = Get-Date -Uformat "%d"
# grabs only the day from date 

# LOGS & ARCHIVE #
$logFile = '\\some\network\path' + $dateDay + ".txt"
# log file for when files are moved 
$logArchive = '\\some\network\path' + $dateDay + '.txt'
# log file for when files are pulled to archive
$logNetwork = '\\some\network\path' + $dateDay + '.txt'
# log file for when files are pulled from processing folder to destination folder 
$archive = "\\some\network\path"
# archive folder - archives all files - static location

#PROCESSING AND FINAL DESTINATION #
$processingDestination = '\\some\network\path'
#processing folder - temporary destination until it moves to network folder - static location
$networkFolder = '\\some\network\path'
# destination of network  folder - static location 

# ARRAYS #
$userComps = @(Import-CSV "\\some\network\path.csv")
#user array pulled from csv 
$folderList =@(Import-CSV "\\some\network\path.csv")
#array of folder pathways pulled from csv

# Variables 

$whoRan = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
# stores who initiated the script


########################################################



########## Delete Old Log Files & Archive ##############
$CurrentDate = Get-Date
$DatetoDelete = $CurrentDate.AddDays(-27)
#delete files

Get-ChildItem $logFile -Recurse  | Where-Object { $_.LastWriteTime -lt $DatetoDelete } | Remove-Item -force -recurse
Get-ChildItem $logArchive -Recurse  | Where-Object { $_.LastWriteTime -lt $DatetoDelete } | Remove-Item -force -recurse
Get-ChildItem $logNetwork -Recurse  | Where-Object { $_.LastWriteTime -lt $DatetoDelete } | Remove-Item -force -recurse
#delete log files

$dateToNuke = $CurrentDate.AddMonths(-6) 
# deletes archive after 6 months
Get-ChildItem $archive -Recurse  | Where-Object { $_.LastWriteTime -lt $dateToNuke } | Remove-Item -force -recurse
#delete archive 

########################################################


foreach ($user in $userComps) 
#performs action on each user in array 
{       
        foreach($folder in $folderList)
        {       
                $selectAll = $user.computer + '\path\' + $folder.path + "\*"
                # selects all items contained in folders 
                $appendFileName = Get-Random -Maximum 10000 -Minimum 1
                $items = Get-ChildItem $selectAll
                $items | Rename-Item -NewName {$_.BaseName + "_" + $appendFileName + "_" + $user.name + $_.Extension}
                # randomly generated number appends to file. This keeps files with the same name (i.e. Invoice) from overwriting each other / causing exception 
                
                $archivePath = $archive + $folder.path
                Write-Host "Copying $selectAll to $archivePath..." -ForegroundColor Green
                Copy-Item -Path $selectAll -Destination $archivePath -PassThru:$Passthru #copies item and gets status
                if ($Passthru)
                {
                        write-host "Logging transaction..." -BackgroundColor Green -ForegroundColor Black
                        Write-Output "$whoRan moved $selectAll to $archivePath on $date" >> $logArchive
                }
                else
                {
                        Write-Output "NO FILES TO MOVE TO ARCHIVE FROM $($user.computer) $date" >> $logArchive
                }
                # copy items to archive and log it - has to be done before moving the files 

                $processingPath = $processingDestination + $folder.path
                write-host "Moving $selectAll to $processingPath..." -ForegroundColor green
                # points to network folder which integration will pull out of 
                
                Move-Item -Path $selectAll -Destination $processingPath -PassThru:$Passthru
                if ($Passthru)
                {
                        write-host "Logging transaction..." -BackgroundColor Green -ForegroundColor Black
                        Write-Output "$whoRan moved $selectAll to $archivePath on $date" >> $logArchive
                }
                else
                {
                        Write-Output  "NO FILES TO MOVE TO PROCESS FROM $($user.computer) $date" >> $logFile
                }
                write-host "Logging transaction..." -BackgroundColor Green -ForegroundColor Black
                # takes all files from network share and moves to processing folder 

                Write-Output "$whoRan moved $selectAll from $selectAll to $processingPath on $date"  >> $logFile
             
        }
}

foreach($folder in $folderList)
{
        $selectAll = $processingDestination + $folder.path + '\*'
        # selects all items contained in folders 
        $destinationPath = $networkFolder + $folder.path
        Write-Host "Moving $selectAll to $destinationPath..." -ForegroundColor Green
        # points to abbyy folder which integration will pull out of 
        Move-Item -Path $selectAll -Destination  $destinationPath -PassThru:$Passthru
        write-host "Logging transaction..." -BackgroundColor Green -ForegroundColor Black
        Write-Output "$whoRan moved $selectAll to $archivePath on $date" >> $logArchive

        # takes all files from ..\moverprocessing\TMT-Oz\* to final abbyy folder
        write-host "Logging transaction..." -BackgroundColor Green -ForegroundColor Black
        Write-Output "$whoRan moved $filesMove from $processingDestination to $destinationPath on $date" >> $logAbbyy
     
}