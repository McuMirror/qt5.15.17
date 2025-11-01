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

set WindowsTargetPlatformMinVersion=5.1.2600.0
call "%~dp0.github\workflows\VC-LTL helper for nmake.cmd"

set InstallDir="%~dp0Output\x86"

mkdir %InstallDir%

set "OpenSSLRoot=%~dp0openssl"
set "OpenSSLInclude=%OpenSSLRoot%\include"
set "OpenSSLLibRelease=%OpenSSLRoot%\lib\x86"
set "OpenSSLLibDebug=%OpenSSLRoot%\lib\x86d"

if not exist "%OpenSSLLibRelease%\libssl.lib" (
  echo OpenSSL release libraries not found in %OpenSSLLibRelease%
  exit /B 1
)
if not exist "%OpenSSLLibDebug%\libssl.lib" (
  echo OpenSSL debug libraries not found in %OpenSSLLibDebug%
  exit /B 1
)

set "OPENSSL_INCDIR=%OpenSSLInclude%"
set "OPENSSL_LIBDIR=%OpenSSLLibRelease%"
set "OPENSSL_LIBS=/LIBPATH:%OpenSSLLibRelease% libssl.lib libcrypto.lib Crypt32.lib User32.lib Ws2_32.lib Gdi32.lib Advapi32.lib"
set "OPENSSL_LIBS_RELEASE=%OPENSSL_LIBS%"
set "OPENSSL_LIBS_DEBUG=/LIBPATH:%OpenSSLLibDebug% libssl.lib libcrypto.lib Crypt32.lib User32.lib Ws2_32.lib Gdi32.lib Advapi32.lib"

set PATH=%~dp0qtbase\bin;%PATH%

cd /d "%~dp0"

call configure -prefix %InstallDir% -confirm-license -opensource -debug-and-release -force-debug-info -opengl dynamic -no-directwrite -mp -nomake examples -nomake tests -recheck-all -openssl-linked -I "%OpenSSLInclude%" -L "%OpenSSLLibRelease%"
nmake -A

if %ERRORLEVEL% NEQ 0 exit /B %ERRORLEVEL%
nmake install

@endlocal
