$ErrorActionPreference = 'Stop'
function Invoke-Pg([string]$Name, [string[]]$Arguments, [string]$Log) {
    $tool = Join-Path $PgBin "$Name.exe"
    if (!(Test-Path $tool)) { $tool = Join-Path $PgBin "$Name.ps1" }
    if (!(Test-Path $tool)) { throw "PostgreSQL tool missing: $Name in $PgBin" }
    $global:LASTEXITCODE = 0
    $oldPreference = $ErrorActionPreference
    try { $ErrorActionPreference='Continue'; $lines = & $tool @Arguments 2>&1; $code=$LASTEXITCODE }
    finally { $ErrorActionPreference=$oldPreference }
    $lines | Out-File -Encoding utf8 $Log
    if ($code -ne 0) { throw "$Name exit=$code; log=$Log" }
    return ($lines -join "`n")
}
function Get-Metrics([string]$Database,[string]$Log) {
    $sql=@'
SELECT json_build_object('counts',json_build_object(
'categoria',(SELECT count(*) FROM public.categoria),
'cliente',(SELECT count(*) FROM public.cliente),
'producto',(SELECT count(*) FROM public.producto),
'pedido',(SELECT count(*) FROM public.pedido),
'detalle_pedido',(SELECT count(*) FROM public.detalle_pedido)),
'invalid',json_build_object(
'producto_precio_negativo',(SELECT count(*) FROM public.producto WHERE precio_lista<0 OR precio_lista IS NULL),
'producto_stock_negativo',(SELECT count(*) FROM public.producto WHERE stock<0 OR stock IS NULL),
'detalle_cantidad_no_positiva',(SELECT count(*) FROM public.detalle_pedido WHERE cantidad<=0 OR cantidad IS NULL),
'detalle_precio_negativo',(SELECT count(*) FROM public.detalle_pedido WHERE precio_unitario<0 OR precio_unitario IS NULL)));
'@
    $json=Invoke-Pg 'psql' ($connection+@('-X','-v','ON_ERROR_STOP=1','-d',$Database,'-At','-c',$sql)) $Log
    return ($json | ConvertFrom-Json)
}
function Assert-Valid($Metrics) {
    foreach($name in @('categoria','cliente','producto','pedido','detalle_pedido')) {
        if ($null -eq $Metrics.counts.$name) { throw "Missing count: $name" }
    }
    foreach($name in @('producto_precio_negativo','producto_stock_negativo','detalle_cantidad_no_positiva','detalle_precio_negativo')) {
        if ($null -eq $Metrics.invalid.$name -or $Metrics.invalid.$name -ne 0) { throw "Invalid rows or missing check: $name" }
    }
}
