# cloakshell
Powershell reverse shell via WebSockets

### As of December 15, 2022, cloakshell has stopped working on Windows machines. Tested against Windows 10 and 11.

#### Quickstart

On the attacker machine install the dependencies and run the command and control server.

```
pip install -r requirements.txt
python control.py
```

In cloakshell.ps1, change the IP address in the `$endpoint` variable to your attacker's IP address. Now drop it on the client and execute it.

```
.\cloakshell.ps1
```

That's it! You have a (somewhat) functional reverse shell over websockets.
