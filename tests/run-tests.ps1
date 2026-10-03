# Sends questions to the AfriKilo assistant API and prints the answers.
#
# All test events:   .\tests\run-tests.ps1 -Url https://xxxx.execute-api.us-east-1.amazonaws.com
# One question:      .\tests\run-tests.ps1 -Url https://xxxx... -Question "Est-ce gratuit ?"
param(
    [Parameter(Mandatory = $true)][string]$Url,
    [string]$Question
)

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$endpoint = $Url.TrimEnd('/') + '/ask'

function Send-Question([string]$name, [string]$jsonFile) {
    Write-Host "== $name" -ForegroundColor Cyan
    # curl.exe (not the PowerShell curl alias) sends the file's UTF-8 bytes as-is
    $raw = curl.exe -s -w "`n%{http_code}" -X POST $endpoint -H "Content-Type: application/json" --data-binary "@$jsonFile"
    $status = $raw[-1]
    $body = ($raw[0..($raw.Count - 2)] -join "`n") | ConvertFrom-Json
    if ($body.answer) {
        $color = if ($body.blocked) { 'Yellow' } else { 'Green' }
        Write-Host "   HTTP $status | blocked: $($body.blocked) | tokens in/out: $($body.usage.inputTokens)/$($body.usage.outputTokens)" -ForegroundColor $color
        Write-Host "   $($body.answer)"
    } else {
        Write-Host "   HTTP $status | $($body | ConvertTo-Json -Compress)" -ForegroundColor Red
    }
}

if ($Question) {
    $tmp = New-TemporaryFile
    # Write UTF-8 without BOM so accents survive
    [System.IO.File]::WriteAllText($tmp, (@{ question = $Question } | ConvertTo-Json -Compress), (New-Object System.Text.UTF8Encoding $false))
    Send-Question $Question $tmp
    Remove-Item $tmp
} else {
    Get-ChildItem "$PSScriptRoot\events\*.json" | ForEach-Object { Send-Question $_.BaseName $_.FullName }
}
