@echo off
echo ================================================================================
echo SPAWN POSITION TEST RUNNER
echo ================================================================================
echo.
echo This will run the automated spawn position test.
echo Please ensure Godot 4.5+ is installed and in your PATH.
echo.
echo If Godot is not in PATH, edit this file and set GODOT_PATH below:
echo.

REM Set your Godot executable path here if not in PATH
set GODOT_PATH=godot

echo Running test...
echo.

%GODOT_PATH% --headless --quit-after 10 --path "M:\GameProject\megabonk-mobile" scenes/testing/SpawnPositionTest.tscn

echo.
echo ================================================================================
echo TEST COMPLETE
echo ================================================================================
echo.
echo Check the output above for test results.
echo A detailed report has been saved to the user data directory.
echo.
pause
