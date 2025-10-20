@echo off
REM ================================================================
REM Automated Test Runner for Megabonk Mobile
REM Runs all test suites and generates consolidated report
REM ================================================================

echo ================================================================
echo MEGABONK MOBILE - AUTOMATED TEST RUNNER
echo ================================================================
echo.

set GODOT="M:\Godot_v4.5.1-stable_mono_win64\Godot_v4.5.1-stable_mono_win64.exe"
set PROJECT="M:\GameProject\megabonk-mobile"
set TIMESTAMP=%date:~-4,4%%date:~-10,2%%date:~-7,2%_%time:~0,2%%time:~3,2%%time:~6,2%
set TIMESTAMP=%TIMESTAMP: =0%

REM Create test results directory if it doesn't exist
if not exist "..\PROGRESS\test_results" mkdir "..\PROGRESS\test_results"

echo Starting test execution at %date% %time%
echo ------------------------------------------------
echo.

REM Run Shrine System Tests
echo [1/4] Running Shrine System Tests...
%GODOT% --headless --path %PROJECT% res://scenes/testing/ShrineSystemTest.tscn > "..\PROGRESS\test_results\shrine_%TIMESTAMP%.log" 2>&1
echo       Shrine tests complete. Check logs for details.
echo.

REM Run Weapon System Tests
echo [2/4] Running Weapon System Tests...
%GODOT% --headless --path %PROJECT% res://scenes/testing/WeaponSystemTest.tscn > "..\PROGRESS\test_results\weapon_%TIMESTAMP%.log" 2>&1
echo       Weapon tests complete. Check logs for details.
echo.

REM Run Character System Tests
echo [3/4] Running Character System Tests...
%GODOT% --headless --path %PROJECT% res://scenes/testing/CharacterSystemTest.tscn > "..\PROGRESS\test_results\character_%TIMESTAMP%.log" 2>&1
echo       Character tests complete. Check logs for details.
echo.

REM Run Enemy System Tests
echo [4/4] Running Enemy System Tests...
%GODOT% --headless --path %PROJECT% res://scenes/testing/EnemySystemTest.tscn > "..\PROGRESS\test_results\enemy_%TIMESTAMP%.log" 2>&1
echo       Enemy tests complete. Check logs for details.
echo.

echo ------------------------------------------------
echo All tests completed at %date% %time%
echo.

REM Parse results and generate summary
echo Generating test summary...
python generate_test_report.py %TIMESTAMP%

echo ================================================================
echo TEST EXECUTION COMPLETE
echo Results saved to: PROGRESS\test_results\*_%TIMESTAMP%.log
echo Summary report: PROGRESS\test_results\summary_%TIMESTAMP%.txt
echo ================================================================

REM Check if any tests failed
findstr /C:"FAIL" "..\PROGRESS\test_results\*_%TIMESTAMP%.log" > nul
if %ERRORLEVEL% == 0 (
    echo.
    echo WARNING: Some tests have failed! Review logs for details.
    echo Creating bug tasks for failed tests...
    python create_bug_tasks.py %TIMESTAMP%
    exit /b 1
) else (
    echo.
    echo SUCCESS: All tests passed!
    exit /b 0
)