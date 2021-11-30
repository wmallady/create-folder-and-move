# create-folder-and-move
CreateFolders creates a sety of local folders on the user's desktop, and then connects them to a local share. This is useful when a user needs to upload information to a network share such as invoices, PDFs, .xcls, etc. 

MoveLocalToNetwork is the script that moves local files to a network share. This can be set with task scheduler to run at any increment, clearing out all the files of a certain type (or any type) from the folders created. 

PDFgrab is a script that automatically grabs any PDF or TIFF files from your outlook inbox and puts them in a local folder.

Combining these three, it is possible to automate the process of PDFs coming in and being uploaded to a network share, creating logs and archives along the way for troubleshooting. 
