
function Start-OutlookBackup {
    <#
    .SYNOPSIS
        Backup Outlook Contacts and Calendar folders to PST.
    .DESCRIPTION
        This function uses the Outlook COM object to copy the Contacts and Calendar Folders to a PST file.
    .EXAMPLE
        PS C:\> Start-OutlookBackup -EmailAddress user@example.com -Path c:\backup\file.pst
        This example makes a PST file at c:\backup\file.pst and copys the Calendar and Contacts folders of the user@example.com Mailbox 
        to the PST file.
    .INPUTS
        None.
    .OUTPUTS
        None.
    .NOTES
        @torggler
        2018-08-30
        Missing: Error handling, folder selection
    #>
    [cmdletbinding()]
    param(
        [Parameter()]
        [system.io.fileinfo]$Path = (Join-Path -Path $env:USERPROFILE -ChildPath Documents\olBackup.pst),
        [Parameter()]
        [string]$EmailAddress = ("{0}@{1}" -f $env:USERNAME,$env:USERDNSDOMAIN)
    )
    $Outlook = New-Object -ComObject Outlook.Application
    Write-Verbose "Connected to Outlook Profile $($outlook.DefaultProfileName)"
    $NS = $Outlook.GetNamespace('MAPI')
    Write-Verbose "Opened Namespace $($NS.Type)"
    $Store = $NS.Stores | Where-Object {$_.displayname -eq $EmailAddress}
    Write-Verbose "Connected to Store $($Store.DisplayName)"
    $Calendar = $Store.GetDefaultFolder([Microsoft.Office.Interop.Outlook.OlDefaultFolders]"olFolderCalendar")
    $Contacts = $Store.GetDefaultFolder([Microsoft.Office.Interop.Outlook.OlDefaultFolders]"olFolderContacts")
    Write-Verbose "Default Calendar Folder is $($Calendar.Name)"
    Write-Verbose "Default Contacts Folder is $($Contacts.Name)"
    $Outlook.Session.AddStore($Path)
    $PST = $ns.Stores | Where-Object {$_.filepath -eq $Path.Fullname}
    $ca = $Calendar.CopyTo($PST)
    $co = $Contacts.CopyTo($PST)
    Write-Verbose "Backed up $($ca.Items.Count) Calendar Items"
    Write-Verbose "Backed up $($co.Items.Count) Contact Items"
    $PSTRoot = $PST.GetRootFolder()
    $PSTFolder = $NS.Folders.Item($PSTRoot.Name)
    $NS.GetType().InvokeMember('RemoveStore',[System.Reflection.BindingFlags]::InvokeMethod,$null,$NS,($PSTFolder))
}
