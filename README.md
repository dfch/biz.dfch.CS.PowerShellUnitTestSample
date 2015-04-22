# biz.dfch.CS.PowerShellUnitTestSample

This Visual Studio .NET/C# project shows you how to use [Microsoft.VisualStudio.TestTools.UnitTesting](https://msdn.microsoft.com/en-us/library/microsoft.visualstudio.testtools.unittesting.aspx) tools for unit testing of PowerShell code.

You can write a simple [TestMethod](https://msdn.microsoft.com/en-us/library/microsoft.visualstudio.testtools.unittesting.testmethodattribute.aspx) like this that tests the addition of two numbers via PowerShell (rather advanced ...):

	[TestMethod]
	public void doAddNumbersReturns7()
	{
		var x = 3;
		var y = 4;
		var testResult = 7;

		PowerShell ps = PowerShell.Create();
		var results = ps.AddScript( String.Format("return {0} + {1}", x, y) )
			.Invoke();
		var result = results[0];
		Assert.AreEqual(testResult, Convert.ToInt32(result.ToString()));
	}

Here you `Assert` that the `testResult` (which is `7`) equals the actual return from PowerShell. As PowerShell returns its contents as `PSObject` you have to convert it to an `int` first.

The project is built with [log4net](http://logging.apache.org/log4net/) support (you need the assembly/DLL in the same directory as the UnitTest assembly or have it installed in the GAC). So you can direct the (test) output to any device you like (such as File, SYSLOG, etc). In addition the project contains a special `Run` methdo you can call directly from PowerShell to execute all tests (even without Visual Studio installed):

	Add-Type -Path $PWD\UnitTest01.dll
	$ut = New-Object biz.dfch.CS.PowerShellUnitTestSample.UnitTest1
	$ut.Run();

Running the tests will output its results like this:

	2015-04-02 02:42::50.703+02:00|biz.dfch.CS.PowerShellUnitTestSample:UnitTest1.Run: Running tests ...
	2015-04-02 02:42::50.500+02:00|Invoking 'doConvertRandomMultiVarFromBase64ReturnsTrue' ...
	2015-04-02 02:42::50.500+02:00|Invoking 'doConvertRandomMultiVarFromBase64ReturnsTrue' SUCCEEDED.
	2015-04-02 02:42::50.500+02:00|Invoking 'doWriteHostReturnsTrue' ...
	2015-04-02 02:42::50.500+02:00|biz.dfch.CS.PowerShellUnitTestSample:UnitTest1.doWriteHostReturnsTrue
	2015-04-02 02:42::50.578+02:00|Invoking 'doWriteHostReturnsTrue' SUCCEEDED.
	2015-04-02 02:42::50.578+02:00|Invoking 'doWriteHostThrowsCmdletInvocationException' ...
	2015-04-02 02:42::50.578+02:00|biz.dfch.CS.PowerShellUnitTestSample:UnitTest1.doWriteHostThrowsCmdletInvocationException
	2015-04-02 02:42::50.703+02:00|Invoking 'doWriteHostThrowsCmdletInvocationException' SUCCEEDED.
	2015-04-02 02:42::50.703+02:00|biz.dfch.CS.PowerShellUnitTestSample:UnitTest1.Run: Running tests COMPLETED.

If you want to run the tests with the original [MSTest](https://msdn.microsoft.com/en-us/library/jj155804.aspx) agent, you can download and install [Agents for Microsoft Visual Studio 2013](https://www.microsoft.com/en-us/download/confirmation.aspx?id=40750).

## Notes regarding the PowerShell Host in Visual Studio

There are some things to keep in mind when running PowerShell scripts or Cmdlets from a .NET/C# programme:

1. You have to import all modules manually before executing scripts.

2. You have no STDOUT, so functions like `Write-Host` will not work and throw an exception. You can workaround this by implementing a *fake* function for this like `ps.AddScript("function Write-Host {}")`

3. If you are reusing the same `System.Automation.PowerShell` object you have to `Clear()` the comannds before performing a subsequent `Invoke()` otherwise you will re-execute the previous commands again.

4. As written above, PowerShell returns its contents as `PSObject` so you have to make an explicit conversion before comparing a result via `Assert`.

5. The result is always returned as an array (even if only one item is returned, in which case you extract the actual result via `results[0]`)

6. Properties of an `PSObject` can be accessed via `Properties` which is a `PSMemberInfoCollection`. You extract actual properties via `Match(key)[0]` (with corresponding `Name` and `Value` properties).
