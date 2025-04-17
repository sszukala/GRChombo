@echo off
echo ===================================================
echo Building local GRChombo Docker image
echo ===================================================
echo.

echo This will build a Docker image with GRChombo from source.
echo It may take 20-30 minutes depending on your internet connection and CPU.
echo.
echo Press any key to start building...
pause > nul

cd "%~dp0"
echo Building GRChombo Docker image...
echo This may take a while as it compiles the necessary libraries.

REM Build the Docker image
docker build -t grchombo-local .

echo.
if %ERRORLEVEL% EQU 0 (
    echo Build successful! You can now run the GRChombo Docker container.
) else (
    echo Build failed with error code %ERRORLEVEL%.
    echo Please check the error messages above.
)
echo.
pause
