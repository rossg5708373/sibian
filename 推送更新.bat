@echo off
setlocal
set "PS1FILE="
for %%f in ("%~dp0*.ps1") do if not defined PS1FILE set "PS1FILE=%%f"
if not defined PS1FILE (
  echo [ERROR] No .ps1 script found in this folder.
  pause
  exit /b 1
)
powershell -NoProfile -ExecutionPolicy Bypass -File "%PS1FILE%"