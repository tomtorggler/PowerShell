function Send-MailJetMail {
    [cmdletbinding()]
	param(
        [string]$Sender,
        [string]$Recipient,
        [string]$Subject,
        [string]$Text,
        [string]$User,
        [string]$Key
    )

    $body = [ordered]@{
        Messages= @(@{
            to = @(@{email =  $recipient})
            from = @{email =  $Sender ; name = "notification"}
            subject = $Subject 
            TextPart = $Text
        })
    }

    $userkey = $user,$key -join ":" 
    $auth = $userkey | ConvertTo-Base64
    $param = @{
        Uri = "https://api.mailjet.com/v3.1/send" 
        ContentType = "application/json"
        body = ($body | ConvertTo-Json -Depth 4 -Compress) 
        Method = "POST"
        Headers = @{Authorization=("Basic $auth")} 
        UseBasicParsing = [switch]::Present
    }
    $Result = Invoke-RestMethod @param
    if($Result) {
        $Result.Messages
    }
}