	Describe -Tags "Error in Comparisons" "Tests that should fail, but succeed" {

		# not the same, but still succeeds
		It "ShouldBe-IntegerString" {
			3 | Should Be '3';
		}

		# not the same, but still succeeds
		It "ShouldExactlyBe-IntegerString" {
			3 | Should BeExactly '3';
		}

		# not the same, but still succeeds
		It "ShouldBe-StringInteger" {
			'3' | Should Be 3;
		}

		# not the same, but still succeeds
		It "ShouldExactlyBe-StringInteger" {
			'3' | Should BeExactly 3;
		}

	}

	Describe -Tags "Error in Comparisons" "Tests that should succeed, but fail" {

		# not the same, but still fails
		It "ShouldNotBe-IntegerString" {
			3 | Should Not Be '3';
		}

		# not the same, but still fails
		It "ShouldNotExactlyBe-IntegerString" {
			3 | Should Not BeExactly '3';
		}

		# not the same, but still fails
		It "ShouldNotBe-StringInteger" {
			'3' | Should Not Be 3;
		}

		# not the same, but still fails
		It "ShouldNotExactlyBe-StringInteger" {
			'3' | Should Not BeExactly 3;
		}

	}

	Describe -Tags "Correct Comparisons" "Tests that fail as expected" {

		# not the same, fails as expected
		It "ShouldBe-TypedIntegerString" {
			([int] 3) | Should Be ([string] '3');
		}

		# not the same, fails as expected
		It "ShouldBe-TypedStringInteger" {
			([string] '3') | Should Be ([int] 3);
		}

	}
