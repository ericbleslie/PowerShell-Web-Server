function New-ScriptBlockCallback{
    param(
        [parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [scriptblock]$Callback
    )
<#
    .SYNOPSIS
        Allows running ScriptBlocks via .NET async callbacks.
 
    .DESCRIPTION
        Allows running ScriptBlocks via .NET async callbacks. Internally this is
        managed by converting .NET async callbacks into .NET events. This enables
        PowerShell 2.0 to run ScriptBlocks indirectly through Register-ObjectEvent.
		This cmdlet was written by Oisin Grehan.
 
    .PARAMETER Callback
        Specify a ScriptBlock to be executed in response to the callback.
        Because the ScriptBlock is executed by the eventing subsystem, it only has
        access to global scope. Any additional arguments to this function will be
        passed as event MessageData.
         
    .EXAMPLE
        You wish to run a scriptblock in reponse to a callback. Here is the .NET
        method signature:
         
        void Bar(AsyncCallback handler, int blah)
         
        ps> [foo]::bar((New-ScriptBlockCallback { ... }), 42)                        
 
    .OUTPUTS
        A System.AsyncCallback delegate.
#>
    # is this type already defined?    
    if (-not ("CallbackEventBridge" -as [type])) {
        Add-Type @"
            using System;
             
            public sealed class CallbackEventBridge
            {
                public event AsyncCallback CallbackComplete = delegate { };
 
                private CallbackEventBridge() {}
 
                private void CallbackInternal(IAsyncResult result)
                {
                    CallbackComplete(result);
                }
 
                public AsyncCallback Callback
                {
                    get { return new AsyncCallback(CallbackInternal); }
                }
 
                public static CallbackEventBridge Create()
                {
                    return new CallbackEventBridge();
                }
            }
"@
    }
    $bridge = [callbackeventbridge]::create()
    Register-ObjectEvent -input $bridge -EventName callbackcomplete -action $callback -messagedata $args > $null
    $bridge.callback
}

class MimeMapping
{
    $Map = [System.Collections.Generic.Dictionary[String, String]]::new()
    static [String]GetMimeMapping([String]$Extension)
    {
        $Instance = [MimeMapping]::new()

        if ($Instance.Map[$Extension] -ne $Null)
        {
            return $Instance.Map[$Extension]
        }
        else
        {
            return "application/octet-stream"
        }
        
    }

    MimeMapping()
    {
        $this.Map.Add("aac", "audio/aac")
        $this.Map.Add("avi", "video/x-msvideo")
        $this.Map.Add("bin", "application/octet-stream")
        $this.Map.Add("bmp", "image/bmp")
        $this.Map.Add("bz", "application/x-bzip")
        $this.Map.Add("bz2", "application/x-bzip2")
        $this.Map.Add("csh", "application/x-csh")
        $this.Map.Add("css", "text/css")
        $this.Map.Add("csv", "text/csv")
        $this.Map.Add("doc", "application/msword")
        $this.Map.Add("docx", "application/vnd.openxmlformats-officedocument.wordprocessingml.document")
        $this.Map.Add("epub", "application/epub+zip")
        $this.Map.Add("gif", "image/gif")
        $this.Map.Add("htm", "text/html")
        $this.Map.Add("html", "text/html")
        $this.Map.Add("ico", "image/vnd.microsoft.icon")
        $this.Map.Add("jar", "application/java-archive")
        $this.Map.Add("jpeg", "image/jpeg")
        $this.Map.Add("jpg", "image/jpeg")
        $this.Map.Add("js", "text/javascript")
        $this.Map.Add("json", "application/json")
        $this.Map.Add("mid", "audio/midi")
        $this.Map.Add("midi", "audio/midi")
        $this.Map.Add("mp3", "audio/mpeg")
        $this.Map.Add("mpeg", "video/mpeg")
        $this.Map.Add("oga", "audio/ogg")
        $this.Map.Add("ogv", "video/ogg")
        $this.Map.Add("ogx", "application/ogg")
        $this.Map.Add("otf", "font/otf")
        $this.Map.Add("png", "image/png")
        $this.Map.Add("pdf", "application/pdf")
        $this.Map.Add("ppt", "application/vnd.ms-powerpoint")
        $this.Map.Add("pptx", "application/vnd.openxmlformats-officedocument.presentationml.presentation")
        $this.Map.Add("rar", "application/x-rar-compressed")
        $this.Map.Add("rtf", "application/rtf")
        $this.Map.Add("sh", "application/x-sh")
        $this.Map.Add("svg", "image/svg+xml")
        $this.Map.Add("swf", "application/x-shockwave-flash")
        $this.Map.Add("tar", "application/x-tar")
        $this.Map.Add("tif", "image/tiff")
        $this.Map.Add("tiff", "image/tiff")
        $this.Map.Add("ts", "video/mp2t")
        $this.Map.Add("ttf", "font/ttf")
        $this.Map.Add("txt", "text/plain")
        $this.Map.Add("wav", "audio/wav")
        $this.Map.Add("weba", "audio/webm")
        $this.Map.Add("webm", "video/webm")
        $this.Map.Add("webp", "image/webp")
        $this.Map.Add("woff", "font/woff")
        $this.Map.Add("woff2", "font/woff2")
        $this.Map.Add("xhtml", "application/xhtml+xml")
        $this.Map.Add("xls", "application/vnd.ms-excel")
        $this.Map.Add("xlsx", "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet")
        $this.Map.Add("xml", "application/xml")
        $this.Map.Add("zip", "application/zip")
        $this.Map.Add("7z", "application/x-7z-compressed")
    }
}

class Logger
{
    $Config

    Logger($Config)
    {
        $this.Config = $Config
    }

    [Void]Log($Context, $Content)
    {
        $this.AccessLog($Context, $Content)
        #$this.SecurityLog(), etc
    }
    [Void]AccessLog($Context, $Content)
    {
        $Request = $Context.Request
        $Response = $Context.Response
        $LogString = "$($Request.RemoteEndPoint.Address.ToString()) - - $(Get-Date -Format s) `"$($Request.HTTPMethod) $($Request.Url.PathAndQuery) HTTP/$($Request.ProtocolVersion)`" $($Response.StatusCode) $($Content.Length) `"$($Request.URLReferrer)`" `"$($Request.UserAgent)`""
        $this.WriteLog($LogString)
    }
    [Void]WriteLog([String]$LogString)
    {
        Add-Content $this.Config.AccessLog -Value $LogString
    }
}

class Router
{
    $Server
    $Config

    Router($Server, $Config)
    {
        $this.Server = $Server
        $this.Config = $Config
    }

    [Void]Route($Context)
    {
        # Parameterize context variables
        $Request = $Context.Request
        $Response = $Context.Response
        $URL = $Request.URL.LocalPath
        
        # Determine best matching route for $URL, assumes longer paths are better
        $BestRoute = $Null
        
        # Array in ForEach is a PS hack to get the names/paths of each location and still be able to use it for the location properties later
        foreach ($Location in ($this.Config | Get-Member -MemberType NoteProperty | ForEach-Object {$_.Name}))
        {
            # If the URL matches and is longer than previous, set as best route
            if (($URL -Match $Location) -AND ($Location.Length -gt $BestRoute.Length))
            {
                $BestRoute = $Location
            }

            # If a route has Bypass_Score set to true, it will be selected if it matches, even if score is zero
            if (($Location."Bypass_Score") -AND ($URL -Match $Location))
            {
                $BestRoute = $Location
                break
            }
        }

        $Route = $BestRoute

        # Check if route has own root, otherwise use site default
        # if it has own root, rewrite path (internally only) to new root $Path.Replace($Root, "")
        $Root = ""

        if ($this.Config.($Route).Root)
        {
            $Root = $this.Config.($Route).Root.Replace("[^A-Za-z0-9]", "")
            New-PSDrive -Name $Root -PSProvider FileSystem -Root $this.Config.($Route).Root -Scope Global -ErrorAction SilentlyContinue
        }
        else
        {
            $Root = "www"
        }
        


        # Test for files/directories according to try_files directive in route config
        foreach ($Test in $this.Config.($Route)."try_files")
        {
            # Replace placeholder in try_files directive with the requested URL
            $Path = $Test.Replace("`$URL", $URL) -Replace "^$Route", "$($Root):"

            # Escape * to %2A so that wildcards can't be used to enumerate directories
            $Path = $Path.Replace("*", "%2A")

            # If directive has no trailing slash, look for files
            if ($Path -Match "[^/]$")
            {
                if ((Test-Path -Path $Path) -AND ((Get-Item -Path $Path).GetType().Name -eq "FileInfo"))
                {
                    if ($Path -Like "*.ps1")
                    {
                        $this.RunScript($Path, $Context)
                    }
                    else
                    {
                        $this.ServeFile($Path, $Context)
                    }

                    break
                }
            }

            # If directive has trailing slash, look for directories
            if ($Path -Match "/$")
            {
                if ((Test-Path -Path "$Path") -AND ((Get-Item -Path "$Path").GetType().Name -eq "DirectoryInfo"))
                {
                    # Do the thing with the folder, rewrite url with trailing slash if not included
                    if ($URL -NotLike "*/")
                    {
                        $Response.Redirect(($Request.Url.PathAndQuery + "/"))
                        $Response.Close()

                        break
                    }
                    else
                    {
                        # Check if directory has a file listed in the index directive
                        foreach($Index in $this.Server.Config.Index)
                        {
                            if (Test-Path -Path ($Path + $Index))
                            {
                                $Path = $Path + $Index
                                break
                            }
                        }

                        if ($Path -Like "*.ps1")
                        {
                            $this.RunScript($Path, $Context)
                        }
                        elseif ($Path -Like "*.*")
                        {
                            $this.ServeFile($Path, $Context)
                        }
                        else
                        {
                            $this.ServeIndex($Path, $Context)
                        }

                        break
                    }
                }
            }

            if ($Path -Match "=[0-9]{3}")
            {
                # Redirect to error message
                $this.ServeStatus(($Path.Replace("=", "")), $Context)
                break
            }
        }
    }

    [Void]RunScript($Path, $Context)
    {
        $Context.Response.ContentType = "text/html" # Set content type first so that server scripts can modify content type
        $RawContent = Invoke-Expression -Command "$Path"
        $Content = [System.Text.Encoding]::UTF8.GetBytes($RawContent)

        $this.Server.Logger.Log($Context, $Content)

        $Context.Response.ContentLength64 = $Content.Length
        if ($Content.Length -ne 0)
        {
            $Context.Response.OutputStream.Write($Content, 0, $Content.Length)
        }
        $Context.Response.Close()
    }

    [Void]ServeFile($Path, $Context)
    {
        $Content = Get-Content -Encoding Byte -Path $Path -ReadCount 0 -ErrorAction Stop

        $this.Server.Logger.Log($Context, $Content)

        $Context.Response.ContentType = [MimeMapping]::GetMimeMapping(($Path -Split "\." | Select-Object -Last 1))
        $Context.Response.ContentLength64 = $Content.Length
        if ($Content.Length -ne 0)
        {
            $Context.Response.OutputStream.Write($Content, 0, $Content.Length)
        }
        $Context.Response.Close()
    }

    [Void]ServeIndex($Path, $Context)
    {
        # Output string
        $Output = ""
        $CountDirectories = 0
        $CountFiles = 0

        $Children = Get-ChildItem $Path
        $Output += (Get-Content ($this.Server.Config.Template + "/index_header.html"))
        $Output += ("<body><h1>Directory Tree</h1><p><a href=`"" + $Context.Request.URL.LocalPath + "`">"  + $Context.Request.URL.LocalPath + "</a><br>")
        $Output += "├── <a href=`"..`">.. (Parent Directory)</a><br>"

        foreach ($Item in $Children)
        {
            $Filename = $Item.Name
            $EncodedFilename = [URI]::EscapeDataString($Filename)

            if ($Item.Mode -eq "d-----")
            {
                $CountDirectories++

                if ($Filename -NotLike "*/")
                {
                    $Filename += "/"
                    $EncodedFilename += "/"
                }
            }
            else
            {
                $CountFiles++
            }
        
            $Output += ("├── <a href=`"" + $Context.Request.URL.LocalPath + $EncodedFilename + "`">" + $Filename + "</a><br>")
        }

        $Output += "<br><br></p><p>"
        $Output += "$CountDirectories directories, $CountFiles files"
        $Output += "<br><br></p><hr><p class=`"VERSION`">tree v1.7.0 clone in PowerShell by Eric Leslie</p></body>"
        $Output += (Get-Content ($this.Server.Config.Template + "/index_footer.html"))

        $Content = [System.Text.Encoding]::UTF8.GetBytes($Output)

        $this.Server.Logger.Log($Context, $Content)

        $Context.Response.ContentType = "text/html"
        $Context.Response.ContentLength64 = $Content.Length
        if ($Content.Length -ne 0)
        {
            $Context.Response.OutputStream.Write($Content, 0, $Content.Length)
        }
        $Context.Response.Close()
    }

    [Void]ServeStatus($Status, $Context)
    {
        $Content = Get-Content -Encoding Byte -Path ($this.Server.Config.Status + "/$Status.html") -ReadCount 0
		$Context.Response.StatusCode = $Status

        $this.Server.Logger.Log($Context, $Content)

        $Context.Response.ContentType = "text/html"
        $Context.Response.ContentLength64 = $Content.Length
        if ($Content.Length -ne 0)
        {
            $Context.Response.OutputStream.Write($Content, 0, $Content.Length)
        }
        $Context.Response.Close()
    }
}

class PSWebServer
{
    [PSCustomObject]$Config
    [System.Net.HTTPListener]$HTTPListener = (New-Object System.Net.HTTPListener)
    $Callback
    $Logger
    $Router
    [Bool]$Initialized = $False

    # Default Constructor
    PSWebServer([String]$ConfigFile)
    {
        # Checks current directory for config.json
        $ConfigFile = "$(Get-Content $ConfigFile)"
        $this.Config = ConvertFrom-JSON $ConfigFile
    }

    hidden [Void]Initialize()
    {
        # Add prefixes from config file
        foreach ($Prefix in $this.Config.Bind)
        {
            $this.HTTPListener.Prefixes.Add("http://$($Prefix):$($this.Config.Port)$($this.Config.Location)")
        }

        # DEBUG: Add default prefix for any interface
        $this.HTTPListener.Prefixes.Add("http://*:5357/")

        # Create PSDrive
        New-PSDrive -Name www -PSProvider FileSystem -Root $this.Config.Root -Scope Global

        # Create module class instances
        $this.Logger = [Logger]::new($this.Config.Logger)
        $this.Router = [Router]::new($this, $this.Config.Router)

        # Create callback for async listener
        $this.Callback = New-ScriptBlockCallBack $this.Listener
        #$this.HTTPListener | Add-Member Callback $this.Callback
        $this.HTTPListener | Add-Member Config $this.Config
        $this.HTTPListener | Add-Member Logger $this.Logger

        $this.Initialized = $True
    }

    [Void]Start()
    {
        if (!$this.Initialized)
        {
            $this.Initialize()
        }

        $this.HTTPListener.Start()

        for ($i = 0; $i -lt $this.Config.Threads; $i++)
        {
            $this.HTTPListener.BeginGetContext($this.Callback, $this)
        }
    }

    [Void]Stop()
    {
        $this.HTTPListener.Stop()
        $this.HTTPListener.Close()
    }

    [ScriptBlock]$Listener = `
    {
        [cmdletbinding()]
        param($Result)

        try
        {
            $Server = $Result.AsyncState
            $Context = $Server.HTTPListener.EndGetContext($Result)
            $Server.HTTPListener.BeginGetContext($Server.Callback, $Server)
            $Server.Router.Route($Context)
        }
        catch
        {
            Write-Error $Error
            Write-Error $Error.Exception
            Write-Error $Error.Exception.InnerException
            #$GLOBAL:ErrMsg = $Error # Global debug variable for debugging inside current PowerSHell window
        }
    }

    
}

function Start-WebServer
{
    $GLOBAL:Server = [PSWebServer]::new("config.json")
    $GLOBAL:Server.Start()

    Write-Host "OK!" -ForegroundColor Green
}

function Stop-WebServer
{
    $GLOBAL:Server.Stop()

    Write-Host "Stopped" -ForegroundColor Red
}