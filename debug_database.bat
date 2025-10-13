@echo off
echo Running Driven Repairs Database Debug Tool...
echo.

REM Check if Flutter is available
where flutter >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo Error: Flutter not found in PATH!
    echo Make sure Flutter is installed and added to your PATH.
    pause
    exit /b 1
)

REM Run the debug tool
dart run debug_database.dart

echo.
pause