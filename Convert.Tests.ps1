#Requires -Modules 'biz.dfch.PS.System.Utilities'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
# . "$here\Add-Numbers.ps1"

function Build ($version) {
    Write-Host "a build was run for version: $version"
}

function Get-Version()
{
	return 0.3;
}

function Get-NextVersion()
{
	return 0.4;
}

function BuildIfChanged {
    $thisVersion = Get-Version
    $nextVersion = Get-NextVersion
    if ($thisVersion -ne $nextVersion) { Build $nextVersion }
    return $nextVersion
}

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".")
# . "$here\$sut"

Describe "BuildIfChanged" {
    Context "When there are Changes" {
        Mock Get-Version {return 1.1}
        Mock Get-NextVersion {return 1.2}
        Mock Build {} -Verifiable -ParameterFilter {$version -eq 1.2}

        $result = BuildIfChanged

        It "Builds the next version" {
            Assert-VerifiableMocks
        }
        It "returns the next version number" {
            $result | Should Be 1.3
        }
    }
    Context "When there are no Changes" {
        Mock Get-Version { return 1.1 }
        Mock Get-NextVersion { return 1.1 }
        Mock Build {}

        $result = BuildIfChanged

        It "Should not build the next version" {
            Assert-MockCalled Build -Times 0 -ParameterFilter {$version -eq 1.1}
        }
    }
}

Describe -Tags "Example" "BasicTests" {

    # It "adds positive numbers" {
        # Add-Numbers 2 3 | Should Be 5
    # }

    # It "adds negative numbers" {
        # Add-Numbers (-2) (-2) | Should Be (-4)
    # }

    # It "adds one negative number to positive number" {
        # Add-Numbers (-2) 2 | Should Be 0
    # }

    # It "concatenates strings if given strings" {
        # Add-Numbers two three | Should Be "twothree"
    # }

    It "doTestShouldBe-ReturnsTrue" {
        3 | Should BeExactly '3'
    }

    It "ConvertTo-Base64ReturnsTrue" {
        "tralala" | ConvertTo-Base64 | Should Be 'dHJhbGFsYQ=='
    }

    It "ConvertTo-Base64ReturnsFalse" {
        "tralala" | ConvertTo-Base64 | Should Not Be 'dHJhbGFsYQ==!!'
    }

    It "TestWillFailThrowsUnexpectedException"	{
        1/0 | Should Be $true;
    }

    It "ThrowsAnyException"	{
        { 1/0 } | Should Throw;
    }

	It "TestWillFailThrowsWrongException" {
		try
		{
			1/0;
		}
		catch
		{
			$exception = $_.Exception.InnerException.GetType();
		}
		$exception | Should Be ([ArgumentNullException])
	}
}
