function ValidateDisks()
{
	$diskCount = @(Get-Disk).Count
	
	if ($diskCount -lt 1)
	{
		throw ("No disks found, missing driver or wrong OS set for VM?")
	}
}

function ValidateNetworks()
{
	$nicCount = @(Get-WmiObject win32_networkadapterconfiguration).Count
	
	if ($nicCount -lt 1)
	{
		throw ("No NIC's found, missing driver or wrong VM network adapter set?")
	}
}

function BlockForNetwork()
{
	$tries = 0
	do 
	{  		
		Write-Progress -Activity "Waiting for network to start" -Status "Attempt $tries of 20"
		$tries++
  		sleep 10
		ping -n 1 10.125.80.2 | Out-Null
	} 
	until(($LASTEXITCODE -eq 0) -or ($tries -gt 20)) #Test-NetConnection not available with PE
	
	Write-Progress -Activity "Waiting for network to start" -Completed
	
	if ($tries -gt 20)
	{
		throw ("Network was not available after 20 tries.")
	}
}

function EnsureFileDirectoryExists($filePath)
{
	$dirPath = [IO.Path]::GetDirectoryName($filePath)
	EnsureDirectoryExists $dirPath
}

function EnsureDirectoryExists($dirPath)
{	
	New-Item -Path $dirPath -ItemType directory -ErrorAction SilentlyContinue | Out-Null
}

function DownloadFile($source, $destination)
{
	EnsureFileDirectoryExists $destination
	
	try 
	{
		Write-Progress -Activity "Downloading $source"
        $client = (New-Object System.Net.WebClient)
        $macslist = BuildMacList
        
        for($i=0; $i -le $macslist.Count; $i++){
            $mac = ([array]($macslist))[$i]
            if (![string]::IsNullOrEmpty($mac))
            {
                $headerKey = ("X-RHN-PROVISIONING-MAC-" + $i)
                $headerValue = ("eth" + $i + " " + $mac)
                Write-Host "Adding header ${headerKey} with value ${headerValue}"
                $client.Headers.Add($headerKey, $headerValue);
            }
        }
        
        $client.DownloadFile($source, $destination)
    } 
    catch [System.Net.WebException] 
	{
        $errorCode = $_.Exception.Response.StatusCode
		
		throw ("Error $errorCode encountered when downloading $source")
    }
	finally
	{
		Write-Progress -Activity "Downloading $source" -Completed
	}
}

function BuildMacList()
{    
	return (Get-WmiObject win32_networkadapterconfiguration | ? {![string]::IsNullOrEmpty($_.MacAddress)} | % {$_.MacAddress})
}

function JoinList($list)
{
	return ($list -join ",")
}

function BuildForemanUnattendUrl($foreman, $type)
{
	return [string]::Format("http://{0}/unattended/{1}", $foreman, $type)
}

function DownloadForemanUnattendFile($foreman, $type, $destination)
{
	$foremanurl = BuildForemanUnattendUrl $foreman $type
	DownloadFile $foremanurl $destination
}

function MountDrive($letter, $path)
{
	#Drop trailing \
	$path = $path.TrimEnd("\")
	
	try
	{
		New-PSDrive –Name $letter –PSProvider FileSystem –Root $path
	}
	catch [System.IO.IOException]
	{
		throw ("Error mounting $path to $letter")
	}
}

function HttpPathToFSPath($root, $path)
{
	Join-Path $root ([Uri]$path).AbsolutePath
}

function SetInterfaceWithMac($mac, $ip, $cidr, $gateway, $domain, $dns)
{
	$interface = Get-NetAdapter | ? {$_.MacAddress.ToLower().Replace("-",":") -eq $mac.ToLower()} | Select -First 1
		
	if ($interface -ne $null)
	{			
        Remove-NetIPAddress -InterfaceAlias $interface.Name -Confirm:$false
		Set-DnsClient -InterfaceAlias $interface.Name -ConnectionSpecificSuffix $domain
		New-NetIPAddress -InterfaceAlias $interface.Name -AddressFamily IPv4 -IPAddress $ip -PrefixLength $cidr -DefaultGateway $gateway
		Set-DnsClientServerAddress -InterfaceAlias $interface.Name -ServerAddresses $dns
	}
	else
	{
		Write-Warning "Mac address $mac not found"
	}
}