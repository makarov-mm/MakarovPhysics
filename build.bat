@echo off
setlocal EnableExtensions
cd /d "%~dp0"

set "CONFIG=Release"
set "PLATFORM=Win32"

rem --- Make sure the Delphi MSBuild environment is available ---
where msbuild >nul 2>nul
if errorlevel 1 (
  if defined BDS if exist "%BDS%\bin\rsvars.bat" call "%BDS%\bin\rsvars.bat"
)
where msbuild >nul 2>nul
if errorlevel 1 (
  echo.
  echo [ERROR] msbuild was not found.
  echo Run this from the "RAD Studio Command Prompt", or set BDS to your Delphi
  echo install, e.g.  set BDS=C:\Program Files ^(x86^)\Embarcadero\Studio\23.0
  exit /b 1
)

echo === [1/3] Building engine, tools, modules and launcher ===
msbuild physic.groupproj /t:Build /p:Config=%CONFIG% /p:Platform=%PLATFORM% /nologo /v:m
if errorlevel 1 goto :fail

echo === [2/3] Building texture packer ===
msbuild data\bmp2dat\bmp2dat.dproj /t:Build /p:Config=%CONFIG% /p:Platform=%PLATFORM% /nologo /v:m
if errorlevel 1 goto :fail

echo === [3/3] Packing textures ===
data\bmp2dat\bmp2dat.exe data\textures\skybox  256 data\textures\skybox.dat
if errorlevel 1 goto :fail
data\bmp2dat\bmp2dat.exe data\textures\preview 512 data\textures\preview.dat
if errorlevel 1 goto :fail

echo.
echo === BUILD COMPLETE ===
echo physic.exe + engine.dll + MakarovTools.dll + module DLLs + textures are in place.
echo Run physic.exe from this folder.
exit /b 0

:fail
echo.
echo *** BUILD FAILED (errorlevel %errorlevel%) ***
exit /b 1
