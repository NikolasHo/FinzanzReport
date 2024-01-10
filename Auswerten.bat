@echo off
echo Starte die Auswertung

powershell.exe "%~dp0parse.ps1"

echo Die Auswertung ist abgeschlossen. Oeffne die Auswertung.html per Doppelklick.
pause