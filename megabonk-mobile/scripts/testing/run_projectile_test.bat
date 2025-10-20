@echo off
REM Automated test runner for RangedEnemy projectile collision fix
echo ============================================================
echo RANGED ENEMY PROJECTILE COLLISION TEST
echo ============================================================
echo.
echo This test will verify that enemy projectiles properly
echo collide with the player after the collision layer fix.
echo.

REM Try to find Godot executable
set GODOT_PATH=
if exist "C:\Program Files\Godot\Godot.exe" set GODOT_PATH=C:\Program Files\Godot\Godot.exe
if exist "C:\Program Files (x86)\Godot\Godot.exe" set GODOT_PATH=C:\Program Files (x86)\Godot\Godot.exe
if exist "C:\Godot\Godot.exe" set GODOT_PATH=C:\Godot\Godot.exe

REM Check if Godot was found
if "%GODOT_PATH%"=="" (
    echo ERROR: Could not find Godot executable.
    echo Please edit this file and set GODOT_PATH to your Godot installation.
    echo Example: set GODOT_PATH=C:\path\to\Godot.exe
    echo.
    pause
    exit /b 1
)

echo Found Godot at: %GODOT_PATH%
echo.
echo Running test...
echo.

REM Run the test scene
"%GODOT_PATH%" --headless --path "%~dp0..\.." res://scenes/testing/RangedEnemyProjectileTest.tscn

echo.
echo Test complete! Check the output above for results.
echo.
pause
