@echo off
REM Databricks dbt Streaming Platform - Local Setup Script (Windows)

echo ==================================
echo dbt Streaming Medallion Setup
echo ==================================
echo.

REM Check Python version
echo Checking Python version...
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Python is not installed or not in PATH
    exit /b 1
)
python --version
echo.

REM Create virtual environment
echo Creating Python virtual environment...
if not exist "venv" (
    python -m venv venv
    echo Virtual environment created
) else (
    echo Virtual environment already exists
)
echo.

REM Activate virtual environment
call venv\Scripts\activate.bat
echo Virtual environment activated
echo.

REM Upgrade pip
echo Upgrading pip...
python -m pip install --upgrade pip
echo.

REM Install Python dependencies
echo Installing Python dependencies...
pip install -r requirements.txt
echo Dependencies installed
echo.

REM Create .dbt directory
echo Setting up dbt configuration...
if not exist "%USERPROFILE%\.dbt" (
    mkdir "%USERPROFILE%\.dbt"
)

REM Check if profiles.yml exists
if not exist "%USERPROFILE%\.dbt\profiles.yml" (
    echo profiles.yml not found in %USERPROFILE%\.dbt\
    echo Please do one of the following:
    echo 1. Copy profiles.yml to %%USERPROFILE%%\.dbt\
    echo 2. Or manually create %%USERPROFILE%%\.dbt\profiles.yml with your Databricks credentials
) else (
    echo profiles.yml found
)
echo.

REM Create .env file from template
if not exist ".env" (
    echo Creating .env file from template...
    copy .env.example .env
    echo Please edit .env file with your Databricks credentials
    echo notepad .env
) else (
    echo .env file already exists
)
echo.

REM Download dbt packages
echo Downloading dbt packages...
dbt deps
echo dbt packages installed
echo.

REM Validate dbt setup
echo Validating dbt setup...
dbt debug --profiles-dir %USERPROFILE%\.dbt
echo.

echo ==================================
echo Setup Complete!
echo ==================================
echo.
echo Next steps:
echo 1. Update your credentials in %%USERPROFILE%%\.dbt\profiles.yml
echo 2. Update environment variables in .env
echo 3. Create Databricks resources (catalog, schemas, cluster)
echo 4. Run: dbt seed --profiles-dir %%USERPROFILE%%\.dbt
echo 5. Run: dbt run --profiles-dir %%USERPROFILE%%\.dbt
echo.
echo For deployment:
echo - Setup GitHub secrets (see DEPLOYMENT.md)
echo - Deploy with: databricks bundle deploy --target dev
echo.
