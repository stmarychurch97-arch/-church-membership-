@echo off
setlocal enabledelayedexpansion
cd /d "%~dp0"

echo ============================================================
echo   Church Membership (Windows Desktop Builder)
echo ============================================================
echo.

set "PY_CMD="
where python >nul 2>nul && set "PY_CMD=python"
if not defined PY_CMD (
    where py >nul 2>nul && set "PY_CMD=py -3"
)
if not defined PY_CMD if exist "%LocalAppData%\Programs\Python\Python311\python.exe" set "PY_CMD=%LocalAppData%\Programs\Python\Python311\python.exe"
if not defined PY_CMD if exist "%LocalAppData%\Programs\Python\Python312\python.exe" set "PY_CMD=%LocalAppData%\Programs\Python\Python312\python.exe"
if not defined PY_CMD if exist "%ProgramFiles%\Python311\python.exe" set "PY_CMD=%ProgramFiles%\Python311\python.exe"

if not defined PY_CMD (
    echo [INFO] Python was not found. Attempting automatic install via winget...
    where winget >nul 2>nul
    if errorlevel 1 (
        echo [ERROR] Python 3.11+ is required. Please install it from https://www.python.org/downloads/
        echo         Make sure to check "Add Python to PATH" during installation.
        pause
        exit /b 1
    )
    winget install -e --id Python.Python.3.11 --silent --accept-package-agreements --accept-source-agreements
    if exist "%LocalAppData%\Programs\Python\Python311\python.exe" (
        set "PY_CMD=%LocalAppData%\Programs\Python\Python311\python.exe"
    ) else (
        where python >nul 2>nul && set "PY_CMD=python"
    )
)

if not defined PY_CMD (
    echo [ERROR] Python installation finished or could not be located. Please close and re-run this script.
    pause
    exit /b 1
)

if not exist "venv\Scripts\python.exe" (
    echo [1/5] Creating virtual environment...
    %PY_CMD% -m venv venv
    if errorlevel 1 (
        echo [ERROR] Failed to create virtual environment.
        pause
        exit /b 1
    )
)

echo [2/5] Installing required Python packages...
call venv\Scripts\activate.bat
python -m pip install --upgrade pip >nul 2>nul
pip install -r requirements.txt
if errorlevel 1 (
    echo [ERROR] Failed to install packages. Check your internet connection during build.
    pause
    exit /b 1
)

echo [3/5] Generating application icon...
python assets\make_icon.py

echo [4/5] Building standalone Windows executable via PyInstaller...
pyinstaller --noconfirm packaging\church_members.spec
if errorlevel 1 (
    echo [ERROR] PyInstaller build failed.
    pause
    exit /b 1
)

echo [5/5] Building Setup Installer via Inno Setup (if installed)...
set "ISCC="
if exist "%ProgramFiles(x86)%\Inno Setup 6\ISCC.exe" set "ISCC=%ProgramFiles(x86)%\Inno Setup 6\ISCC.exe"
if exist "%ProgramFiles%\Inno Setup 6\ISCC.exe" set "ISCC=%ProgramFiles%\Inno Setup 6\ISCC.exe"

if defined ISCC (
    "%ISCC%" "packaging\installer.iss"
    if not errorlevel 1 (
        echo.
        echo [SUCCESS] Installer created at:
        echo   %~dp0dist_installer\Setup_ChurchMembership_v1.0.exe
        explorer "%~dp0dist_installer"
        pause
        exit /b 0
    )
)

echo.
echo [SUCCESS] Standalone executable built at:
echo   %~dp0dist\ChurchMembership\ChurchMembership.exe
echo Creating Desktop shortcut...
powershell -NoProfile -ExecutionPolicy Bypass -Command "$root = (Get-Location).Path; $desk = [Environment]::GetFolderPath('Desktop'); $name = ([char]0x0639)+([char]0x0636)+([char]0x0648)+([char]0x064A)+([char]0x0629)+' '+([char]0x0643)+([char]0x0646)+([char]0x0633)+([char]0x064A)+([char]0x0629); $ws = New-Object -ComObject WScript.Shell; $sc = $ws.CreateShortcut((Join-Path $desk ($name + '.lnk'))); $exeDir = Join-Path $root 'dist\ChurchMembership'; $sc.TargetPath = (Join-Path $exeDir 'ChurchMembership.exe'); $sc.WorkingDirectory = $exeDir; $ico = Join-Path $root 'assets\church_icon.ico'; if (Test-Path $ico) { $sc.IconLocation = $ico }; $sc.Save()"
explorer "%~dp0dist\ChurchMembership"
pause
