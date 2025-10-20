@echo off
echo ================================================================================
echo RUNNING AUTOMATED SHRINE SYSTEM TESTS
echo ================================================================================
echo.

REM Change to the megabonk-mobile directory
cd megabonk-mobile

REM Run Godot headless with the test scene
REM Note: Adjust the Godot path if your installation is different
REM Common paths:
REM   - C:\Program Files\Godot\Godot_v4.x.exe
REM   - C:\Godot\Godot_v4.x.exe
REM   - Just "godot" if it's in your PATH

REM Try to find Godot in common locations
set GODOT_PATH=
if exist "C:\Program Files\Godot\Godot_v4.3-stable_win64.exe" set GODOT_PATH=C:\Program Files\Godot\Godot_v4.3-stable_win64.exe
if exist "C:\Godot\Godot_v4.3-stable_win64.exe" set GODOT_PATH=C:\Godot\Godot_v4.3-stable_win64.exe

REM If Godot found, run tests
if "%GODOT_PATH%"=="" (
    echo ERROR: Could not find Godot installation.
    echo Please edit run_shrine_tests.bat and set the correct GODOT_PATH
    echo.
    echo Trying with 'godot' command assuming it's in PATH...
    godot --headless --path . res://scenes/testing/ShrineSystemTest.tscn
) else (
    echo Found Godot at: %GODOT_PATH%
    echo.
    "%GODOT_PATH%" --headless --path . res://scenes/testing/ShrineSystemTest.tscn
)

echo.
echo ================================================================================
echo TEST RUN COMPLETE
echo ================================================================================
echo.
pause
