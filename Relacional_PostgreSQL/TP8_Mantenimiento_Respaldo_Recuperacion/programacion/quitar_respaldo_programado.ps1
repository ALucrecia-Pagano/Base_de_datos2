# TPI Base de Datos II — Objetivo 7: quita la tarea de respaldo programado.
# No borra respaldos ya generados.

[CmdletBinding()]
param(
    [string]$TaskName = 'FoodStore_Respaldo_Diario'
)

$ErrorActionPreference = 'Stop'
Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
Write-Output "Tarea $TaskName eliminada."
