@echo off
setlocal enabledelayedexpansion
cd /d "%~dp0"

echo ============================================================
echo   Church Membership - Windows Setup and Launch
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
        echo [ERROR] Python 3.11+ is required. Download it from:
        echo         https://www.python.org/downloads/
        echo         Check "Add Python to PATH" during setup, then run this file again.
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
    echo [ERROR] Python installation finished or could not be located.
    echo         Please close this window, reopen it, and run this script again.
    pause
    exit /b 1
)

if not exist "venv\Scripts\python.exe" (
    echo [1/3] Creating virtual environment...
    %PY_CMD% -m venv venv
    if errorlevel 1 (
        echo [ERROR] Failed to create Python virtual environment.
        pause
        exit /b 1
    )
)

echo [2/3] Installing required packages...
call venv\Scripts\activate.bat
python -m pip install --upgrade pip >nul 2>nul
pip install -r requirements.txt
if errorlevel 1 (
    echo [ERROR] Failed to install dependencies. Please verify internet connection for first setup.
    pause
    exit /b 1
)

python assets\make_icon.py

echo [3/3] Creating Desktop shortcut and starting application...
powershell -NoProfile -ExecutionPolicy Bypass -Command "$root = (Get-Location).Path; $desk = [Environment]::GetFolderPath('Desktop'); $name = ([char]0x0639)+([char]0x0636)+([char]0x0648)+([char]0x064A)+([char]0x0629)+' '+([char]0x0643)+([char]0x0646)+([char]0x0633)+([char]0x064A)+([char]0x0629); $ws = New-Object -ComObject WScript.Shell; $sc = $ws.CreateShortcut((Join-Path $desk ($name + '.lnk'))); $sc.TargetPath = (Join-Path $root 'venv\Scripts\pythonw.exe'); $sc.Arguments = ('\"' + (Join-Path $root 'main.py') + '\"'); $sc.WorkingDirectory = $root; $ico = Join-Path $root 'assets\church_icon.ico'; if (Test-Path $ico) { $sc.IconLocation = $ico }; $sc.Save()"

start "" "%~dp0venv\Scripts\pythonw.exe" "%~dp0main.py"
