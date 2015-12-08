#Requires -Version 3
[CmdletBinding(
	SupportsShouldProcess = $true
	,
	ConfirmImpact = 'Low'
	,
	DefaultParameterSetName = 'all'
)]
Param
(
	[Parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 0, ParameterSetName = 'name')]
	[Alias('Name')]
	$InputObject
	,
	[Parameter(Mandatory = $false, Position = 0, ParameterSetName = 'all')]
	[Switch]
	[Alias('a')]
	[Alias('RunAllTests')]
	$All = $true
	,
	[Parameter(Mandatory = $false, ParameterSetName = 'list')]
	[Switch]
	$ListAvailable = $true
	,
	[ValidateScript( { Test-Path($_) -PathType Leaf; } )]
	[ValidateNotNullOrEmpty()]
	[Parameter(Mandatory = $false)]
	[String]
	$Path = "${ENV:ProgramFiles(x86)}\Microsoft Visual Studio 12.0\Common7\IDE\PublicAssemblies\Microsoft.VisualStudio.QualityTools.UnitTestFramework.dll"
)

BEGIN
{
	[Boolean] $fReturn = $false;
	$OutputParameter  = @();
	$_MyInvocation = $MyInvocation;
	[PowerShell] $Script:ps = $null;
	$Script:Assert = $null;

	function Configure()
	{
		# Write-Host "Configure";
		Add-Type -Path $Path -ErrorAction:Stop;
		Set-Variable -Name Assert -Value ([Microsoft.VisualStudio.TestTools.UnitTesting.Assert]) -Scope Script;
	}

	function classInitialize()
	{
		# Write-Host "classInitialize";
	}

	function classCleanup()
	{
		# Write-Host "classCleanup";
	}

	function testInitialize()
	{
		# Write-Host "testInitialize";
		Set-Variable -Name ps -Value ([PowerShell]::Create()) -Scope Script;
	}

	function testCleanup()
	{
		# Write-Host "testCleanup";
		if($ps) 
		{
			$ps.Dispose();
		}
	}

	function runTestMethod($Object)
	{
		if(!$PSCmdlet.ShouldProcess($Object)) 
		{
			return @{$Object = "ShouldProcessFalse"};
		}
		testInitialize;
		Write-Host ("Testing '{0}' ..." -f $Object);
		Write-Progress -Activity $Object -Status Running;
		$isExceptionThrown = $false;
		$datNow = [DateTime]::Now;
		try
		{
			if($aTestMethods -notcontains $Object)
			{
				Write-Warning ("'{0}' does not exist in this test file. Skipping ..." -f $Object);
				$OutputParameter.$Object = "TestNotFound";
			}
			Invoke-Expression $Object;
		}
		catch 
		{
			$isExceptionThrown = $true;
			[string] $ErrorText = $_.ScriptStackTrace;
			if($_.Exception.InnerException)
			{
				if($_.Exception.InnerException.GetType().Name -eq "AssertFailedException")
				{
					throw $_.Exception.InnerException;
				}
				if($Object -imatch "Throws(?<Exception>\w+)$")
				{
					$Assert::AreEqual($Matches.Exception, $_.Exception.InnerException.GetType().Name);
				}
				else
				{
					Write-Host ("{0}: '{1}' @{2}`n{3}" -f $Object, $_.Exception.InnerException.Message, $_.Exception.InnerException.GetType().Name, $ErrorText);
					$OutputParameter.$Object = $false;
					$Assert::AreEqual("No exception was expected", $_.Exception.InnerException.GetType().Name)
				}
			}
			else
			{
				Write-Host ("{0}: '{1}' @{2}`n{3}" -f $Object, $_.Exception.Message, $_.Exception.GetType(), $ErrorText);
			}
		}
		finally
		{
			$datEnd = [datetime]::Now;
			$datDeltaMs = ($datEnd - $datNow).TotalMilliseconds;
			$OutputParameter.$Object = $datDeltaMs;
			if(!$isExceptionThrown -And $Object -imatch "Throws(?<Exception>\w+)$")
			{
				try
				{
					$Assert::AreEqual($Matches.Exception, "No exception has been thrown");
				}
				finally
				{
					$OutputParameter.$Object = $false;
				}
			}
		}
		Write-Progress -Activity $Object -Completed;
		Write-Host ("Testing {0} SUCCEEDED. [{1}ms]" -f $Object, $datDeltaMs);
		testCleanup;
	}

	function getTestMethods($_MyInvocation)
	{
		$OutputParameter = @();
		# foreach($BlockName in @("BeginBlock", "ProcessBlock", "EndBlock"))
		foreach($BlockName in @("ProcessBlock"))
		{
			$CurrentBlock = $_MyInvocation.MyCommand.ScriptBlock.Ast.$BlockName;
			foreach($Statement in $CurrentBlock.Statements)
			{
				$Extent = $Statement.Extent.ToString();
				if([String]::IsNullOrWhiteSpace($Statement.Name) -Or $Extent -inotmatch ('function\W+(?<name>{0})' -f $Statement.Name))
				{
					continue;
				}
				$OutputParameter += $Statement.Name;
			}
		}
		return $OutputParameter;
	}
	
	Configure;
}

PROCESS
{

# Tests a Base64 conversion that succeeds.
# This test will succeed.
function doConvertToBase64ReturnsTrue()
{

$Command = 
@'
	Import-Module biz.dfch.PS.System.Utilities;

	$test = 42;

	"tralala" | ConvertTo-Base64

'@

	$results = Invoke-Expression -Command $Command;
	if($results -is [Array])
	{
		$result = $results[0];
	}
	else
	{
		$result = $results;
	}
	$Assert::AreEqual('dHJhbGFsYQ==', $result.ToString());
}

# Tests a Base64 conversion that fails, but is expected.
# This test will succeed.
function doConvertToBase64ReturnsFalse()
{

$Command = 
@'
	Import-Module biz.dfch.PS.System.Utilities;

	$test = 42;

	"tralala" | ConvertTo-Base64

'@

	$results = Invoke-Expression -Command $Command;
	if($results -is [Array])
	{
		$result = $results[0];
	}
	else
	{
		$result = $results;
	}
	$Assert::AreNotEqual('dHJhbGFsYQ==!', $result);

}

# A "DivideByZeroException" is expected, and is thrown. 
# This will cause the test to succeed.
function doDivideThrowsDivideByZeroException()
{

$Command = 
@'
	1/0;
'@

	$results = Invoke-Expression -Command $Command;

}

# A "DivideByZeroException" is expected, but it not thrown. 
# This will cause the test to fail.
function doExceptionNotThrownThrowsDivideByZeroException()
{

$Command = 
@'
	1/1;
'@

	$results = Invoke-Expression -Command $Command;
	if($results -is [Array])
	{
		$result = $results[0];
	}
	else
	{
		$result = $results;
	}
}

# A "DivideByZeroException2" is expected, but it is not thrown. 
# This will cause the test to fail.
function doWrongExceptionThrowsInvalidException()
{

$Command = 
@'
	1/0;
'@

	$results = Invoke-Expression -Command $Command;
	if($results -is [Array])
	{
		$result = $results[0];
	}
	else
	{
		$result = $results;
	}
}

try 
{
	$aTestMethods = getTestMethods($_MyInvocation);
	if($PSCmdlet.ParameterSetName -eq 'list') 
	{
		$OutputParameter = $aTestMethods;
	}
	else
	{
		$OutputParameter = @{};
		if($PSCmdlet.ParameterSetName -eq 'all') 
		{
			$InputObject = $aTestMethods;
		}
		classInitialize;
		foreach($Object in $InputObject) 
		{
			try
			{
				runTestMethod($Object);
			}
			catch
			{
				Write-Warning $_.Exception.InnerException.Message;
			}
		}
		classCleanup;
	}
}
catch 
{
	Write-Host ("{0}: '{1}' @{2}" -f $Object, $_.Exception.Message, $_.Exception.GetType());
}

}

END
{
	return $OutputParameter;
}

# 
# Copyright 2015 d-fens GmbH
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
# http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# 


# SIG # Begin signature block
# MIIXDwYJKoZIhvcNAQcCoIIXADCCFvwCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUVcxHESv4ctCz/5ciPvh2c4Gg
# Qx6gghHCMIIEFDCCAvygAwIBAgILBAAAAAABL07hUtcwDQYJKoZIhvcNAQEFBQAw
# VzELMAkGA1UEBhMCQkUxGTAXBgNVBAoTEEdsb2JhbFNpZ24gbnYtc2ExEDAOBgNV
# BAsTB1Jvb3QgQ0ExGzAZBgNVBAMTEkdsb2JhbFNpZ24gUm9vdCBDQTAeFw0xMTA0
# MTMxMDAwMDBaFw0yODAxMjgxMjAwMDBaMFIxCzAJBgNVBAYTAkJFMRkwFwYDVQQK
# ExBHbG9iYWxTaWduIG52LXNhMSgwJgYDVQQDEx9HbG9iYWxTaWduIFRpbWVzdGFt
# cGluZyBDQSAtIEcyMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAlO9l
# +LVXn6BTDTQG6wkft0cYasvwW+T/J6U00feJGr+esc0SQW5m1IGghYtkWkYvmaCN
# d7HivFzdItdqZ9C76Mp03otPDbBS5ZBb60cO8eefnAuQZT4XljBFcm05oRc2yrmg
# jBtPCBn2gTGtYRakYua0QJ7D/PuV9vu1LpWBmODvxevYAll4d/eq41JrUJEpxfz3
# zZNl0mBhIvIG+zLdFlH6Dv2KMPAXCae78wSuq5DnbN96qfTvxGInX2+ZbTh0qhGL
# 2t/HFEzphbLswn1KJo/nVrqm4M+SU4B09APsaLJgvIQgAIMboe60dAXBKY5i0Eex
# +vBTzBj5Ljv5cH60JQIDAQABo4HlMIHiMA4GA1UdDwEB/wQEAwIBBjASBgNVHRMB
# Af8ECDAGAQH/AgEAMB0GA1UdDgQWBBRG2D7/3OO+/4Pm9IWbsN1q1hSpwTBHBgNV
# HSAEQDA+MDwGBFUdIAAwNDAyBggrBgEFBQcCARYmaHR0cHM6Ly93d3cuZ2xvYmFs
# c2lnbi5jb20vcmVwb3NpdG9yeS8wMwYDVR0fBCwwKjAooCagJIYiaHR0cDovL2Ny
# bC5nbG9iYWxzaWduLm5ldC9yb290LmNybDAfBgNVHSMEGDAWgBRge2YaRQ2XyolQ
# L30EzTSo//z9SzANBgkqhkiG9w0BAQUFAAOCAQEATl5WkB5GtNlJMfO7FzkoG8IW
# 3f1B3AkFBJtvsqKa1pkuQJkAVbXqP6UgdtOGNNQXzFU6x4Lu76i6vNgGnxVQ380W
# e1I6AtcZGv2v8Hhc4EvFGN86JB7arLipWAQCBzDbsBJe/jG+8ARI9PBw+DpeVoPP
# PfsNvPTF7ZedudTbpSeE4zibi6c1hkQgpDttpGoLoYP9KOva7yj2zIhd+wo7AKvg
# IeviLzVsD440RZfroveZMzV+y5qKu0VN5z+fwtmK+mWybsd+Zf/okuEsMaL3sCc2
# SI8mbzvuTXYfecPlf5Y1vC0OzAGwjn//UYCAp5LUs0RGZIyHTxZjBzFLY7Df8zCC
# BCkwggMRoAMCAQICCwQAAAAAATGJxjfoMA0GCSqGSIb3DQEBCwUAMEwxIDAeBgNV
# BAsTF0dsb2JhbFNpZ24gUm9vdCBDQSAtIFIzMRMwEQYDVQQKEwpHbG9iYWxTaWdu
# MRMwEQYDVQQDEwpHbG9iYWxTaWduMB4XDTExMDgwMjEwMDAwMFoXDTE5MDgwMjEw
# MDAwMFowWjELMAkGA1UEBhMCQkUxGTAXBgNVBAoTEEdsb2JhbFNpZ24gbnYtc2Ex
# MDAuBgNVBAMTJ0dsb2JhbFNpZ24gQ29kZVNpZ25pbmcgQ0EgLSBTSEEyNTYgLSBH
# MjCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAKPv0Z8p6djTgnY8YqDS
# SdYWHvHP8NC6SEMDLacd8gE0SaQQ6WIT9BP0FoO11VdCSIYrlViH6igEdMtyEQ9h
# JuH6HGEVxyibTQuCDyYrkDqW7aTQaymc9WGI5qRXb+70cNCNF97mZnZfdB5eDFM4
# XZD03zAtGxPReZhUGks4BPQHxCMD05LL94BdqpxWBkQtQUxItC3sNZKaxpXX9c6Q
# MeJ2s2G48XVXQqw7zivIkEnotybPuwyJy9DDo2qhydXjnFMrVyb+Vpp2/WFGomDs
# KUZH8s3ggmLGBFrn7U5AXEgGfZ1f53TJnoRlDVve3NMkHLQUEeurv8QfpLqZ0BdY
# Nc0CAwEAAaOB/TCB+jAOBgNVHQ8BAf8EBAMCAQYwEgYDVR0TAQH/BAgwBgEB/wIB
# ADAdBgNVHQ4EFgQUGUq4WuRNMaUU5V7sL6Mc+oCMMmswRwYDVR0gBEAwPjA8BgRV
# HSAAMDQwMgYIKwYBBQUHAgEWJmh0dHBzOi8vd3d3Lmdsb2JhbHNpZ24uY29tL3Jl
# cG9zaXRvcnkvMDYGA1UdHwQvMC0wK6ApoCeGJWh0dHA6Ly9jcmwuZ2xvYmFsc2ln
# bi5uZXQvcm9vdC1yMy5jcmwwEwYDVR0lBAwwCgYIKwYBBQUHAwMwHwYDVR0jBBgw
# FoAUj/BLf6guRSSuTVD6Y5qL3uLdG7wwDQYJKoZIhvcNAQELBQADggEBAHmwaTTi
# BYf2/tRgLC+GeTQD4LEHkwyEXPnk3GzPbrXsCly6C9BoMS4/ZL0Pgmtmd4F/ximl
# F9jwiU2DJBH2bv6d4UgKKKDieySApOzCmgDXsG1szYjVFXjPE/mIpXNNwTYr3MvO
# 23580ovvL72zT006rbtibiiTxAzL2ebK4BEClAOwvT+UKFaQHlPCJ9XJPM0aYx6C
# WRW2QMqngarDVa8z0bV16AnqRwhIIvtdG/Mseml+xddaXlYzPK1X6JMlQsPSXnE7
# ShxU7alVrCgFx8RsXdw8k/ZpPIJRzhoVPV4Bc/9Aouq0rtOO+u5dbEfHQfXUVlfy
# GDcy1tTMS/Zx4HYwggSfMIIDh6ADAgECAhIRIQaggdM/2HrlgkzBa1IJTgMwDQYJ
# KoZIhvcNAQEFBQAwUjELMAkGA1UEBhMCQkUxGTAXBgNVBAoTEEdsb2JhbFNpZ24g
# bnYtc2ExKDAmBgNVBAMTH0dsb2JhbFNpZ24gVGltZXN0YW1waW5nIENBIC0gRzIw
# HhcNMTUwMjAzMDAwMDAwWhcNMjYwMzAzMDAwMDAwWjBgMQswCQYDVQQGEwJTRzEf
# MB0GA1UEChMWR01PIEdsb2JhbFNpZ24gUHRlIEx0ZDEwMC4GA1UEAxMnR2xvYmFs
# U2lnbiBUU0EgZm9yIE1TIEF1dGhlbnRpY29kZSAtIEcyMIIBIjANBgkqhkiG9w0B
# AQEFAAOCAQ8AMIIBCgKCAQEAsBeuotO2BDBWHlgPse1VpNZUy9j2czrsXV6rJf02
# pfqEw2FAxUa1WVI7QqIuXxNiEKlb5nPWkiWxfSPjBrOHOg5D8NcAiVOiETFSKG5d
# QHI88gl3p0mSl9RskKB2p/243LOd8gdgLE9YmABr0xVU4Prd/4AsXximmP/Uq+yh
# RVmyLm9iXeDZGayLV5yoJivZF6UQ0kcIGnAsM4t/aIAqtaFda92NAgIpA6p8N7u7
# KU49U5OzpvqP0liTFUy5LauAo6Ml+6/3CGSwekQPXBDXX2E3qk5r09JTJZ2Cc/os
# +XKwqRk5KlD6qdA8OsroW+/1X1H0+QrZlzXeaoXmIwRCrwIDAQABo4IBXzCCAVsw
# DgYDVR0PAQH/BAQDAgeAMEwGA1UdIARFMEMwQQYJKwYBBAGgMgEeMDQwMgYIKwYB
# BQUHAgEWJmh0dHBzOi8vd3d3Lmdsb2JhbHNpZ24uY29tL3JlcG9zaXRvcnkvMAkG
# A1UdEwQCMAAwFgYDVR0lAQH/BAwwCgYIKwYBBQUHAwgwQgYDVR0fBDswOTA3oDWg
# M4YxaHR0cDovL2NybC5nbG9iYWxzaWduLmNvbS9ncy9nc3RpbWVzdGFtcGluZ2cy
# LmNybDBUBggrBgEFBQcBAQRIMEYwRAYIKwYBBQUHMAKGOGh0dHA6Ly9zZWN1cmUu
# Z2xvYmFsc2lnbi5jb20vY2FjZXJ0L2dzdGltZXN0YW1waW5nZzIuY3J0MB0GA1Ud
# DgQWBBTUooRKOFoYf7pPMFC9ndV6h9YJ9zAfBgNVHSMEGDAWgBRG2D7/3OO+/4Pm
# 9IWbsN1q1hSpwTANBgkqhkiG9w0BAQUFAAOCAQEAgDLcB40coJydPCroPSGLWaFN
# fsxEzgO+fqq8xOZ7c7tL8YjakE51Nyg4Y7nXKw9UqVbOdzmXMHPNm9nZBUUcjaS4
# A11P2RwumODpiObs1wV+Vip79xZbo62PlyUShBuyXGNKCtLvEFRHgoQ1aSicDOQf
# FBYk+nXcdHJuTsrjakOvz302SNG96QaRLC+myHH9z73YnSGY/K/b3iKMr6fzd++d
# 3KNwS0Qa8HiFHvKljDm13IgcN+2tFPUHCya9vm0CXrG4sFhshToN9v9aJwzF3lPn
# VDxWTMlOTDD28lz7GozCgr6tWZH2G01Ve89bAdz9etNvI1wyR5sB88FRFEaKmzCC
# BNYwggO+oAMCAQICEhEhDRayW4wRltP+V8mGEea62TANBgkqhkiG9w0BAQsFADBa
# MQswCQYDVQQGEwJCRTEZMBcGA1UEChMQR2xvYmFsU2lnbiBudi1zYTEwMC4GA1UE
# AxMnR2xvYmFsU2lnbiBDb2RlU2lnbmluZyBDQSAtIFNIQTI1NiAtIEcyMB4XDTE1
# MDUwNDE2NDMyMVoXDTE4MDUwNDE2NDMyMVowVTELMAkGA1UEBhMCQ0gxDDAKBgNV
# BAgTA1p1ZzEMMAoGA1UEBxMDWnVnMRQwEgYDVQQKEwtkLWZlbnMgR21iSDEUMBIG
# A1UEAxMLZC1mZW5zIEdtYkgwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIB
# AQDNPSzSNPylU9jFM78Q/GjzB7N+VNqikf/use7p8mpnBZ4cf5b4qV3rqQd62rJH
# RlAsxgouCSNQrl8xxfg6/t/I02kPvrzsR4xnDgMiVCqVRAeQsWebafWdTvWmONBS
# lxJejPP8TSgXMKFaDa+2HleTycTBYSoErAZSWpQ0NqF9zBadjsJRVatQuPkTDrwL
# eWibiyOipK9fcNoQpl5ll5H9EG668YJR3fqX9o0TQTkOmxXIL3IJ0UxdpyDpLEkt
# tBG6Y5wAdpF2dQX2phrfFNVY54JOGtuBkNGMSiLFzTkBA1fOlA6ICMYjB8xIFxVv
# rN1tYojCrqYkKMOjwWQz5X8zAgMBAAGjggGZMIIBlTAOBgNVHQ8BAf8EBAMCB4Aw
# TAYDVR0gBEUwQzBBBgkrBgEEAaAyATIwNDAyBggrBgEFBQcCARYmaHR0cHM6Ly93
# d3cuZ2xvYmFsc2lnbi5jb20vcmVwb3NpdG9yeS8wCQYDVR0TBAIwADATBgNVHSUE
# DDAKBggrBgEFBQcDAzBCBgNVHR8EOzA5MDegNaAzhjFodHRwOi8vY3JsLmdsb2Jh
# bHNpZ24uY29tL2dzL2dzY29kZXNpZ25zaGEyZzIuY3JsMIGQBggrBgEFBQcBAQSB
# gzCBgDBEBggrBgEFBQcwAoY4aHR0cDovL3NlY3VyZS5nbG9iYWxzaWduLmNvbS9j
# YWNlcnQvZ3Njb2Rlc2lnbnNoYTJnMi5jcnQwOAYIKwYBBQUHMAGGLGh0dHA6Ly9v
# Y3NwMi5nbG9iYWxzaWduLmNvbS9nc2NvZGVzaWduc2hhMmcyMB0GA1UdDgQWBBTN
# GDddiIYZy9p3Z84iSIMd27rtUDAfBgNVHSMEGDAWgBQZSrha5E0xpRTlXuwvoxz6
# gIwyazANBgkqhkiG9w0BAQsFAAOCAQEAAApsOzSX1alF00fTeijB/aIthO3UB0ks
# 1Gg3xoKQC1iEQmFG/qlFLiufs52kRPN7L0a7ClNH3iQpaH5IEaUENT9cNEXdKTBG
# 8OrJS8lrDJXImgNEgtSwz0B40h7bM2Z+0DvXDvpmfyM2NwHF/nNVj7NzmczrLRqN
# 9de3tV0pgRqnIYordVcmb24CZl3bzpwzbQQy14Iz+P5Z2cnw+QaYzAuweTZxEUcJ
# bFwpM49c1LMPFJTuOKkUgY90JJ3gVTpyQxfkc7DNBnx74PlRzjFmeGC/hxQt0hvo
# eaAiBdjo/1uuCTToigVnyRH+c0T2AezTeoFb7ne3I538hWeTdU5q9jGCBLcwggSz
# AgEBMHAwWjELMAkGA1UEBhMCQkUxGTAXBgNVBAoTEEdsb2JhbFNpZ24gbnYtc2Ex
# MDAuBgNVBAMTJ0dsb2JhbFNpZ24gQ29kZVNpZ25pbmcgQ0EgLSBTSEEyNTYgLSBH
# MgISESENFrJbjBGW0/5XyYYR5rrZMAkGBSsOAwIaBQCgeDAYBgorBgEEAYI3AgEM
# MQowCKACgAChAoAAMBkGCSqGSIb3DQEJAzEMBgorBgEEAYI3AgEEMBwGCisGAQQB
# gjcCAQsxDjAMBgorBgEEAYI3AgEVMCMGCSqGSIb3DQEJBDEWBBRnLrGYZKT7Jm1d
# 99NT0uKoBYJ4kzANBgkqhkiG9w0BAQEFAASCAQAtfdj3vLe6H8DR1GTK42v8bhrE
# 6fJXTFEaTuZEQp2QN8UiCTZnjS4ZoQ0K/lZ7x5I6/fDiQrx5qPF3MoW+NJFyNBLz
# UC5FypPYmUAn4enutRzjCO8G3x3tM4dGoa2u1yVwq+5gHPuvJosYTG1ODchVO2yU
# dW1j38/fBPRVlIGC9iNVaZFXVMr5omUb7TbwZA9rfWlc+kQ2d9I9FuJ54tuSkafV
# a/+TuS8MHmdAjqtF7xx9JRnLNktitxmjnq7d5cmXADFI5gNsfI8YM/jnZE0pfGs0
# /0T3Xy27JE99R//57n9iNvb0ZWxiCn4znrzed5gPnc7IWYBpYx8Oqx+h7lHboYIC
# ojCCAp4GCSqGSIb3DQEJBjGCAo8wggKLAgEBMGgwUjELMAkGA1UEBhMCQkUxGTAX
# BgNVBAoTEEdsb2JhbFNpZ24gbnYtc2ExKDAmBgNVBAMTH0dsb2JhbFNpZ24gVGlt
# ZXN0YW1waW5nIENBIC0gRzICEhEhBqCB0z/YeuWCTMFrUglOAzAJBgUrDgMCGgUA
# oIH9MBgGCSqGSIb3DQEJAzELBgkqhkiG9w0BBwEwHAYJKoZIhvcNAQkFMQ8XDTE1
# MTEyNjA2NDkzN1owIwYJKoZIhvcNAQkEMRYEFEVtkOa6BNUh40UNvsM8Sg1YQ7vQ
# MIGdBgsqhkiG9w0BCRACDDGBjTCBijCBhzCBhAQUs2MItNTN7U/PvWa5Vfrjv7Es
# KeYwbDBWpFQwUjELMAkGA1UEBhMCQkUxGTAXBgNVBAoTEEdsb2JhbFNpZ24gbnYt
# c2ExKDAmBgNVBAMTH0dsb2JhbFNpZ24gVGltZXN0YW1waW5nIENBIC0gRzICEhEh
# BqCB0z/YeuWCTMFrUglOAzANBgkqhkiG9w0BAQEFAASCAQBsE6IxmWV7TzJNen50
# 20Hb+s+Cf2srzH1z+EomdnGfDDJs141vYB2ZrxrfnmcwjmwktZP+8iwWgLp93/1A
# e7kBp9DI+vYj4A6eJTGhoflBtCta/FhVSHyAVFQC0chFdLzKzdBEApXqK0NU/xfL
# Rqv4HmPl579vJstNwwhgYUIk31ABB3hnYUDOD0xKnIqe4V31BEeQhocGDDboMpUi
# mUAU6a0xY2aWFNdw/pKXtPARzBnoWAm+tAGZohI26s8jPJ8suX66z3PC/fLw+33F
# 8ymt0R1MZygfhUxIcgogHgTvUrPbGchP+1ATNtfNhTH6wRFi3lvN8Vi+JhZ7SWs1
# aI23
# SIG # End signature block
