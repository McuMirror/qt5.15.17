@setlocal

@echo off

set VisualStudioInstallerFolder="%ProgramFiles(x86)%\Microsoft Visual Studio\Installer"
if %PROCESSOR_ARCHITECTURE%==x86 set VisualStudioInstallerFolder="%ProgramFiles%\Microsoft Visual Studio\Installer"

pushd %VisualStudioInstallerFolder%
for /f "usebackq tokens=*" %%i in (`vswhere -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath`) do (
  set VisualStudioInstallDir=%%i
)
popd

call "%VisualStudioInstallDir%\VC\Auxiliary\Build\vcvarsall.bat" amd64_x86

set InstallDir="%~dp0Output\x86"

mkdir %InstallDir%

set PATH=%~dp0qtbase\bin;%PATH%

cd /d "%~dp0"

configure -prefix %InstallDir% -confirm-license -opensource -release -force-debug-info -opengl dynamic -no-directwrite -mp -nomake examples -nomake tests -recheck-all

if %ERRORLEVEL% NEQ 0 exit /B %ERRORLEVEL%

nmake

if %ERRORLEVEL% NEQ 0 exit /B %ERRORLEVEL%
nmake install

@endlocal