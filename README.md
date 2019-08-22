# PSWebServer — A web server written in PowerShell

PSWebServer is an experimental web server written in PowerShell during some of my free time. It was designed with minimal concern for security, performance, or reliability so use in a production environment is not recommended.

Currently there are built-in helper functions to the .ps1 file that create a class instance and start the server. These may be removed later and replaced with something else.

## Getting Started

### Requirements
- PowerShell (5 or higher, not sure on the exact version)
- Windows
	- You might be able to get it to work on PowerShell builds for other OS's but I haven't tried

### Usage
Copy the included `config.sample.json` to `config.json` and make any desired changes to paths.
Put any static files you want served under the Root directory.
`.ps1` files can be used to serve dynamic content, a super rough example `index.sample.ps1` is provided.

```powershell
Import-Module PSWebServer.ps1
Start-WebServer
```

## Documentation
Non-existent, have a look through the source if you want.

## Developer's $0.02
This web server was hacked together in a short amount of time, originally without organization or design to just get it working. The last month or so has been spent refactoring it to something *resembling* object-oriented programming.

## Feedback / Suggestions
Definitely open to any suggestions or improvements, they may or may not be implemented because I'm lazy and don't expect this to be used much.

## License
GNU General Public License v3.0, see `LICENSE`