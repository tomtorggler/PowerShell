# just testing...
# connect to exchange online
# Connect-Exchange -Online -Credential (Get-Credential)
#
# update rule daily (scheduled task)
# Get-InboxRule -Mailbox tom -Identity move_night |
# Set-InboxRule 
#-ExceptIfReceivedAfterDate (Get-Date 06:00)
#-ExceptIfReceivedBeforeDate (Get-Date 15:00)
#
#Get-Mailbox tom | New-OffHoursFolder -Name "_offhours" -Verbose
#Get-Mailbox tom | Get-OffHoursFolder -Name night
#Get-Mailbox tom | Get-OffHoursRule -Name _offhours
#Get-Mailbox tom | New-OffHoursRule -Name move_offhours -MoveToFolder _offhours -StartTime 08:00 -EndTime 17:00 -Verbose
#

function Connect-Exchange
{
    [CmdletBinding()]
    Param
    (
        # Credential used for connection
        [Parameter(Mandatory=$true)]
        [pscredential]
        $Credential
    )
        $params = @{
            ConnectionUri = "https://outlook.office365.com/powershell-liveid/";
            ConfigurationName = "Microsoft.Exchange";
            Credential = $Credential;
            Authentication = "Basic";
            AllowRedirection = $true;
        }
    try {
        Write-Verbose "Trying to connect to $($params.ConnectionUri)"
        $sExch = New-PSSession @params -ErrorAction Stop -ErrorVariable ExchangeSessionError -Verbose:$false
	    Import-PSSession $sExch
    } catch {
        Write-Warning "Could not connect to Exchange $($ExchangeSessionError.ErrorRecord)"
    }
}

# Returns Inbox Rule for a Mailbox
# If rulename or mailbox not found, returns nothing
function Get-OffHoursRule {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Mailbox,
        [ValidateNotNullOrEmpty()]
        [string]
        $Name
    )
    process {
        Get-InboxRule -Mailbox $mailbox -Identity $Name -ErrorAction SilentlyContinue
    }
}

function New-OffHoursRule {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline=$true)]
        [ValidateNotNullOrEmpty()]
        $Mailbox,
        [ValidateNotNullOrEmpty()]
        [string]
        $Name,
        [ValidateNotNullOrEmpty()]
        [string]
        $MoveToFolder,
        $StartTime,
        $EndTime
    )
    process {
        # Check if target folder already exists
        $mbxFolder = Get-OffHoursFolder -Mailbox $Mailbox -Name $MoveToFolder
        # Create folder if doesn't exist
        if(-not($mbxFolder)){
            $mbxFolder = New-OffHoursFolder -Mailbox $Mailbox -Name $MoveToFolder
        }
        # create folder id string in format: mailbox:\foldername
        $folderId = $Mailbox.Identity,$mbxFolder.Name -join ":\"
        Write-Verbose "Folder Id is $folderId"
        # Create Rule
        if(-not(Get-OffHoursRule -Mailbox $Mailbox -Name $Name)){
            $params = @{
                Mailbox = $Mailbox;
                Name = $Name;
                ExceptIfReceivedAfterDate = (Get-Date $StartTime).ToUniversalTime();
                ExceptIfReceivedBeforeDate = (Get-Date $EndTime).ToUniversalTime();
                MoveToFolder = $folderId;
            }
            Write-Verbose "Create Rule $Name in Mailbox $Mailbox"
            Write-Verbose "Move mails before $StartTime and after $EndTime to folder: $FolderId"
            New-InboxRule @params   
        }
    }
}

function Update-OffHoursRule {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline=$true)]
        [ValidateNotNullOrEmpty()]
        $Mailbox,
        $Name,
        $StartTime,
        $EndTime
    )
    process {
        $params = @{
            ExceptIfReceivedAfterDate = (Get-Date $StartTime).ToUniversalTime();
            ExceptIfReceivedBeforeDate = (Get-Date $EndTime).ToUniversalTime();
        }
        Get-OffHoursRule -Mailbox $Mailbox -Name $Name | Set-InboxRule @params
    }
}

function Get-OffHoursFolder {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Mailbox,
        [ValidateNotNullOrEmpty()]
        [string]
        $Name
    )
    process {
        Get-MailboxFolder -Identity "$Mailbox`:\$Name" -ErrorAction SilentlyContinue
    }
}

function New-OffHoursFolder {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Mailbox,
        [ValidateNotNullOrEmpty()]
        [string]
        $Name
    )
    process {
        if(Get-MailboxFolder -Identity "$Mailbox`:\$Name" -ErrorAction SilentlyContinue) {
            Write-Verbose "Folder $Name exists in Mailbox $($Mailbox.Identity)"
        } else {
            New-MailboxFolder -Parent $Mailbox -Name $Name
        }
    }
}
