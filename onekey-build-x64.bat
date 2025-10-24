@setlocal

@echo off

set VisualStudioInstallerFolder="%ProgramFiles(x86)%\Microsoft Visual Studio\Installer"
if %PROCESSOR_ARCHITECTURE%==x86 set VisualStudioInstallerFolder="%ProgramFiles%\Microsoft Visual Studio\Installer"

pushd %VisualStudioInstallerFolder%
for /f "usebackq tokens=*" %%i in (`vswhere -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath`) do (
  set VisualStudioInstallDir=%%i
)
popd

call "%VisualStudioInstallDir%\VC\Auxiliary\Build\vcvarsall.bat" amd64

set WindowsTargetPlatformMinVersion=5.1.2600.0
call "%~dp0.github\workflows\VC-LTL helper for nmake.cmd"

set InstallDir="%~dp0Output\x64"

mkdir %InstallDir%

set PATH=%~dp0qtbase\bin;%PATH%

cd /d "%~dp0"

call configure -prefix %InstallDir% -confirm-license -opensource -debug-and-release -force-debug-info -opengl dynamic -no-directwrite -mp -nomake examples -nomake tests -recheck-all
nmake

if %ERRORLEVEL% NEQ 0 exit /B %ERRORLEVEL%
nmake install

@endlocal