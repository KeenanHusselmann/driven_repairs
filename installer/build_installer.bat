@echo off
echo Building Driven Repairs Installer...
echo.

REM Check if Flutter build exists
if not exist "..\build\windows\x64\runner\Release\driven_repairs.exe" (
    echo Error: Flutter release build not found!
    echo Please run: flutter build windows --release
    echo.
    pause
    exit /b 1
)

REM Check if Inno Setup is installed
where iscc >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo Error: Inno Setup Compiler not found!
    echo Please install Inno Setup from: https://jrsoftware.org/isinfo.php
    echo Make sure to add it to your PATH or use the full path to iscc.exe
    echo.
    pause
    exit /b 1
)

REM Create output directory
if not exist "..\build\installer" mkdir "..\build\installer"

REM Compile the installer
echo Compiling installer...
iscc "driven_repairs_setup.iss"

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ✓ Installer created successfully!
    echo Location: ..\build\installer\DrivenRepairs_Setup_v1.0.0.exe
    echo.
    echo You can now distribute this installer to users.
) else (
    echo.
    echo ✗ Installer compilation failed!
    echo Check the error messages above.
)

echo.
pause