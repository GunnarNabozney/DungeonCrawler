# BatchTest 1.0

BatchTest is the standalone test framework for every reusable DungeonCrawler engine component.

It is implemented as a caller-state batch helper so existing suites can continue using readable `call` commands without introducing a second runtime or test language.

## Compatibility

The original helper path remains available:

```bat
Engine\BatchRuntime\BatchTest.bat
```

That file is now a thin compatibility shim to:

```bat
Engine\BatchTest\BatchTest.bat
```

Existing Runtime tests keep their local path and therefore verify compatibility. Other engine suites reference the standalone framework directly.

## Suite lifecycle

```bat
call "%BatchTest%" begin suite "Component deterministic self-test"
call "%BatchTest%" finish suite
```

The framework prints the standard assertion lines and summary:

```text
[PASS] Assertion description
[FAIL] Assertion description - detail

=================================
Tests: N
Passed: N
Failed: N
RESULT: PASS
```

Skipped assertions are reported only when present.

## Assertions

Legacy syntax remains supported:

```bat
call "%BatchTest%" expect exit "%ActualExit%" to equal 0 because "Operation succeeds"
call "%BatchTest%" expect value "%Actual%" to equal Expected because "Value matches"
call "%BatchTest%" record pass because "Manual check passed"
call "%BatchTest%" record failure because "Manual check failed"
```

Additional assertions:

```bat
call "%BatchTest%" expect value "%Actual%" not to equal Forbidden because "Value differs"
call "%BatchTest%" expect error Kind value "%ActualKind%" equals ExpectedKind because "Structured error kind matches"
call "%BatchTest%" expect variable Result to be defined because "Result was produced"
call "%BatchTest%" expect variable Result to be undefined because "Result was not produced"
call "%BatchTest%" expect file "%Path%" to exist because "Fixture file exists"
call "%BatchTest%" expect directory "%Path%" to exist because "Fixture directory exists"
call "%BatchTest%" expect files "%Left%" and "%Right%" to match because "Files match byte-for-byte"
call "%BatchTest%" record skip because "Capability is unavailable"
```

Exit-code assertion failures set `BT.Abort=1` for compatibility with existing suites.

## Setup, teardown, and cases

Setup and teardown hooks are ordinary batch files. They receive the isolated case root as `%1` and case name as `%2`. The environment variable `BT.HookPhase` is `Setup` or `Teardown`.

```bat
call "%BatchTest%" configure setup "%SetupScript%"
call "%BatchTest%" configure teardown "%TeardownScript%"

call "%BatchTest%" begin case "Manual case"
rem Test commands...
call "%BatchTest%" finish case
```

A standalone case script can be run and asserted as one test:

```bat
call "%BatchTest%" run case "%CaseScript%" because "Case exits zero"
call "%BatchTest%" run case "%CaseScript%" expecting exit 7 because "Case returns the expected code"
```

The case script receives the isolated case root as `%1` and case name as `%2`. Teardown runs even when the case returns a failing exit code.

Use `none` to clear a hook:

```bat
call "%BatchTest%" configure setup none
call "%BatchTest%" configure teardown none
```

## Fixtures and isolated temporary state

Every suite receives a unique directory under `%TEMP%`. Every case receives a child directory. The framework removes them automatically.

```bat
call "%BatchTest%" get fixture root into FixtureRoot
call "%BatchTest%" create temporary file into TempFile
call "%BatchTest%" create temporary directory into TempDirectory
call "%BatchTest%" create fixture from "%SourceFile%" into FixtureCopy
```

Fixture copies are binary copies. Temporary output variables are validated and reserved process variables are rejected.

## External summaries

A suite implemented in another approved engine seam can print its individual `[PASS]` and `[FAIL]` lines, write a summary file, and let BatchTest own the final summary.

Summary file format:

```text
Tests=10
Passed=9
Failed=1
Skipped=0
```

Import it before recording local assertions:

```bat
call "%BatchTest%" import summary from "%SummaryFile%"
```

## Statistics

```bat
call "%BatchTest%" get statistic Tests into Actual
call "%BatchTest%" get statistic Passed into Actual
call "%BatchTest%" get statistic Failed into Actual
call "%BatchTest%" get statistic Skipped into Actual
call "%BatchTest%" get statistic CaseCount into Actual
```

## Requirements

- Windows `cmd.exe`
- Command extensions enabled
- Delayed expansion enabled
- No external runtime dependency for the framework itself
