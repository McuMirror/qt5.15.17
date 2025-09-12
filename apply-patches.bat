@setlocal

@echo off

set PatchesFolder="%~dp0Patches"
set QtBaseFolder="%~dp0qtbase"

pushd %QtBaseFolder%
git am %PatchesFolder%\0001-qtbase-support-xp.patch
if %ERRORLEVEL% NEQ 0 exit /B %ERRORLEVEL%
popd

@endlocal