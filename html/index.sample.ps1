#PSW

@"
<html>
    <head>
        <title>PowerShell Web Server</title>
    <head>
    <body>
        <h3>Welcome</h3>
        <div>
            <div><a href="/">Home</a></div>
        </div>
        </br>
        <code>
			2 + 2 = $(2 + 2) </br></br>
			$(
				for ($i = 0; $i -lt 100; $i++)
				{
					Write-Output "$i</br>"
				}
			)
        </code>
    </body>
</html>
"@
