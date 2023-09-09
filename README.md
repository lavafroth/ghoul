# cloakshell
Powershell reverse shell via WebSockets

### Prerequisites

- [Websocat](https://github.com/vi/websocat) installed
- A Windows VM

#### Quickstart

On the host machine, spin up a listener.

```sh
websocat -s 42069 -b
```

In cloakshell.ps1, change the IP address for the `$endpoint` variable to your host's IP address. Now drop it on the client and execute it.

```
.\cloakshell.ps1
```
