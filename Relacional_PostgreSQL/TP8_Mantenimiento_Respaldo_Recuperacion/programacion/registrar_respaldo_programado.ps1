# TPI Base de Datos II — Objetivo 7: respaldo programado.
# Registra en el Programador de tareas de Windows la ejecución diaria de
# backup_foodstore.ps1 (Unidad 6) sobre foodstore_dev.
# La tarea corre con el usuario actual y solo con la sesión iniciada:
# no se guarda ninguna contraseña en el Programador de tareas.
# La autenticación a PostgreSQL usa pgpass.conf (backup_foodstore.ps1 usa -w).

[CmdletBinding()]
param(
    [string]$TaskName = 'FoodStore_Respaldo_Diario',
    [string]$Hora = '23:00'
)

$ErrorActionPreference = 'Stop'

$backup = Join-Path (Split-Path $PSScriptRoot -Parent) 'backup_foodstore.ps1'
if (-not (Test-Path $backup)) {
    throw "No se encontró $backup"
}

if (Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue) {
    throw "La tarea $TaskName ya existe. Se detiene para no sobrescribirla."
}

$accion = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument "-NoProfile -ExecutionPolicy RemoteSigned -File `"$backup`" -SourceDatabase foodstore_dev"
$disparador = New-ScheduledTaskTrigger -Daily -At $Hora
$configuracion = New-ScheduledTaskSettingsSet -StartWhenAvailable -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ExecutionTimeLimit (New-TimeSpan -Hours 1)
$principal = New-ScheduledTaskPrincipal -UserId "$env:USERDOMAIN\$env:USERNAME" -LogonType Interactive -RunLevel Limited

Register-ScheduledTask -TaskName $TaskName -Action $accion -Trigger $disparador -Settings $configuracion -Principal $principal -Description 'TPI BDII: respaldo diario de foodstore_dev con backup_foodstore.ps1 (Unidad 6).' | Out-Null

Get-ScheduledTask -TaskName $TaskName | Select-Object TaskName, State
