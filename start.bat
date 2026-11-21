
@echo off
rem ==== Flame in Freefall: Production Mode ====
rem Requires Python 3.14.x and Node.js 22.x.
rem Creates .venv, installs dependencies, builds frontend,
rem and starts the backend at http://127.0.0.1:5000.

title Flame in Freefall
cd /d "%~dp0"

rem ==================================================
rem Find Python 3.14.x in system PATH
rem ==================================================

set "PY="

echo Searching PATH for Python 3.14.x...

for /f "delims=" %%P in ('where python.exe 2^>nul') do (
    "%%P" -c "import sys; sys.exit(0 if sys.version_info[:2] == (3,14) else 1)" >nul 2>&1

    if not errorlevel 1 (
        if not defined PY set "PY=%%P"
    )
)

if not defined PY (
    echo.
    echo ERROR: Python 3.14.x is required but was not found in PATH.
    echo Install Python 3.14 from:
    echo https://www.python.org/downloads/
    echo Make sure Python is added to PATH.
    pause
    exit /b 1
)

echo Found Python:
echo %PY%

rem ==================================================
rem Find Node.js 22.x in system PATH
rem ==================================================

set "NODE="

echo.
echo Searching PATH for Node.js 22.x...

for /f "delims=" %%P in ('where node.exe 2^>nul') do (
    "%%P" -e "process.exit(Number(process.versions.node.split('.')[0]) === 22 ? 0 : 1)" >nul 2>&1

    if not errorlevel 1 (
        if not defined NODE set "NODE=%%P"
    )
)

if not defined NODE (
    echo.
    echo ERROR: Node.js 22.x is required but was not found in PATH.
    echo Install Node.js 22 LTS from:
    echo https://nodejs.org/en/download
    echo Make sure Node.js is added to PATH.
    pause
    exit /b 1
)

echo Found Node.js:
echo %NODE%

rem Prioritize the selected Node.js installation
for %%D in ("%NODE%") do set "PATH=%%~dpD;%PATH%"

rem Verify npm
where npm.cmd >nul 2>&1

if errorlevel 1 (
    echo.
    echo ERROR: npm was not found.
    echo Reinstall Node.js 22 LTS with npm included.
    pause
    exit /b 1
)

echo.
echo Node version:
node --version
echo npm version:
call npm --version

rem ==================================================
rem Create / validate Python virtual environment
rem ==================================================

if exist ".venv\Scripts\python.exe" (
    ".venv\Scripts\python.exe" -c "import sys; sys.exit(0 if sys.version_info[:2] == (3,14) else 1)" >nul 2>&1

    if errorlevel 1 (
        echo.
        echo Existing .venv does not use Python 3.14.
        echo Recreating virtual environment...
        rmdir /s /q ".venv"
    )
)

if not exist ".venv\Scripts\python.exe" (
    echo.
    echo Creating Python 3.14 virtual environment...

    "%PY%" -m venv .venv

    if errorlevel 1 (
        echo Failed to create virtual environment.
        pause
        exit /b 1
    )
)

set "VENV_PY=%~dp0.venv\Scripts\python.exe"

echo.
echo Using virtual environment:
echo %VENV_PY%

rem ==================================================
rem Environment configuration
rem ==================================================

rem Reuse API key from old dashboard if backend .env is missing
if not exist "backend\.env" if exist "..\flame-dashboard\.env" (
    copy "..\flame-dashboard\.env" "backend\.env" >nul
)

rem Create backend .env from example if necessary
if not exist "backend\.env" (
    copy "backend\.env.example" "backend\.env" >nul
)

rem ==================================================
rem Install backend dependencies
rem ==================================================

echo.
echo Checking Python packages...

"%VENV_PY%" -m pip install --disable-pip-version-check -q -r backend\requirements.txt

if errorlevel 1 (
    echo Python package installation failed.
    pause
    exit /b 1
)

rem ==================================================
rem Build frontend if needed
rem ==================================================

if not exist "frontend\dist\index.html" (
    echo.
    echo Frontend is not built. Building now...

    call build-frontend.bat nopause

    cd /d "%~dp0"

    if not exist "frontend\dist\index.html" (
        echo Frontend build failed. See the messages above.
        pause
        exit /b 1
    )
)

rem ==================================================
rem Start backend
rem ==================================================

echo.
echo ================================================
echo Flame in Freefall is starting!
echo ================================================
echo.
echo Open http://127.0.0.1:5000 in your browser.
echo Keep this window open.
echo.

"%VENV_PY%" backend\app.py

pause

