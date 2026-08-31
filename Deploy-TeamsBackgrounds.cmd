@echo off
setlocal

rem Adjust this path to your domain before deployment.
set "BASE=\\contoso.local\SYSVOL\contoso.local\scripts\Teams-Backgrounds"

powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "%BASE%\Deploy-TeamsBackgrounds.ps1" -SourcePath "%BASE%\bg"

exit /b %ERRORLEVEL%
