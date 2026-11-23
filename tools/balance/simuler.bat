@echo off
rem Lance le simulateur d'equilibrage sans interface.
rem 1. Remplace le chemin ci-dessous par celui de ton executable Godot (une seule fois).
rem 2. Depuis le dossier du projet : .\tools\balance\simuler.bat --games 10

set GODOT=D:\Projets\Godot_v4.7.2-stable_win64_console.exe
set PROJET=%~dp0..\..

if not exist "%GODOT%" (
    echo Executable Godot introuvable : %GODOT%
    echo Ouvre tools\balance\simuler.bat et corrige la ligne "set GODOT=".
    exit /b 1
)

rem Met a jour la liste des classes du projet (nouveaux fichiers) avant de simuler.
echo Mise a jour du projet...
"%GODOT%" --headless --path "%PROJET%" --import >nul 2>&1

"%GODOT%" --headless --path "%PROJET%" --script res://tools/balance/balance_sim.gd -- %*
