function New-TelegramMessage {
    [cmdletbinding()]
    param(
        $ChatId,
        $Text,
        $Mode = "Markdown",
        $ReplyId,
        $ReplyMarkup,
        $ApiKey = $env:TG_Token
    )
    # build body, only add ReplyId and Markup if necessary
    $body = @{
        "parse_mode" = $mode;
        "chat_id"= $ChatId;
        "text" = $Text;
    }
    if($ReplyId) {
        $body.Add("reply_to_message_id",$ReplyId)
    }
    if($ReplyMarkup) {
        $body.Add("reply_markup",(ConvertTo-Json $ReplyMarkup -Depth 5))
    }
    Invoke-RestMethod -Uri https://api.telegram.org/bot$ApiKey/sendMessage -Body $body -Method Post
}
# Send a message using the input values received from the StorageQueue
# Splatting doesn't work with objects created by ConvertFrom-Json
# New-TelegramMessage -ChatId $requestBody.ChatId -Text $requestBody.Text -ReplyId $requestBody.ReplyId -ReplyMarkup $requestBody.ReplyMarkup

function Get-TelegramFilePath {
    [CmdletBinding()]
    param (
        $FileId,
        $ApiKey
    )
    process {
        Write-Verbose "Get File Path for file_id [$FileId]"
        $Result = Invoke-RestMethod -Uri "https://api.telegram.org/bot$ApiKey/getFile?file_id=$FileId" | Select-Object -ExpandProperty Result
        if($Result){
            $Result.file_path
        }
    }
}

function Get-TelegramFile {
    [CmdletBinding()]
    param (
        $FileId,
        $ApiKey,
        $Path
    )
    process {
        $TelegramFilePath = Get-TelegramFilePath -FileId $FileId -ApiKey $ApiKey
        if($TelegramFilePath) {
            $TelegramFileName = Split-Path -Path $TelegramFilePath -Leaf
            $OutputFilePath = Join-Path -Path $Path -ChildPath $TelegramFileName
            Write-Verbose "Download File from [$TelegramFilePath] to [$OutputFilePath]"
            Invoke-WebRequest -Uri "https://api.telegram.org/file/bot$ApiKey/$TelegramFilePath" -UseBasicParsing -OutFile $OutputFilePath
        }
    }
}

# Get-TelegramFile -ApiKey "key" -FileId AgADAgADUasxGxIpWEh0sk6-k2noT0j-tw8ABJ5RD7ZyHEnAoxIAAgI -Path ~\Desktop -Verbose
