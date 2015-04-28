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
		$OutputParameter = aTestMethods;
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
