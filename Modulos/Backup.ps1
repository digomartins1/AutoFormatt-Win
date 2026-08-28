<#
==================================================================
  MODULO AUTOBACKUP-WIN (SEM ACENTOS E VISUAL LIMPO)
==================================================================
#>

function Iniciar-AutoBackup {
    Clear-Host
    Write-Host "********************************************************************************" -ForegroundColor Cyan
    Write-Host "                     ** FERRAMENTA AUTOBACKUP-WIN **                            " -ForegroundColor Yellow
    Write-Host "********************************************************************************" -ForegroundColor Cyan
    Write-Host ""

    # Busca Pendrive ou HD Externo
    $Pendrives = Get-CimInstance Win32_LogicalDisk | Where-Object { $_.DriveType -eq 2 }

    if (-not $Pendrives) {
        Write-Host "[ALERTA] NENHUM PENDRIVE DETECTADO!" -ForegroundColor Red
        Write-Host "Conecte um pendrive para salvar o backup com seguranca." -ForegroundColor Yellow
        Write-Host ""
        $tentarManual = Read-Host "Deseja digitar a letra de um HD Externo manualmente? (S/N)"
        if ($tentarManual -ne 'S' -and $tentarManual -ne 's') {
            Write-Host "`nOperacao cancelada para protecao dos dados." -ForegroundColor Cyan
            Pause
            return
        }
        $Destino = Read-Host "Digite a letra da unidade (ex: D ou E)"
        $Destino = "$($Destino.TrimEnd(':\')):"
    } else {
        $Destino = $Pendrives[0].DeviceID
        Write-Host "[OK] Pendrive detectado na unidade: $Destino ($($Pendrives[0].VolumeName))" -ForegroundColor Green
    }

    # Trava de seguranca
    if ($Destino -eq $env:SystemDrive) {
        Write-Host "`n[ERRO] O destino nao pode ser o mesmo disco do sistema ($env:SystemDrive)!" -ForegroundColor Red
        Pause
        return
    }

    if (-not (Test-Path "$Destino\")) {
        Write-Host "`n[ERRO] Unidade $Destino nao encontrada!" -ForegroundColor Red
        Pause
        return
    }

    $OrigemPath = "$env:SystemDrive\Users"
    $DataHora = Get-Date -Format "yyyy-MM-dd_HH-mm"
    $DestinoPath = "$Destino\Backup_Clientes\$env:COMPUTERNAME`_$DataHora"

    Write-Host "`nIniciando Backup para o Pendrive em: $DestinoPath" -ForegroundColor Cyan
    Write-Host "--------------------------------------------------------" -ForegroundColor DarkGray

    $PastasAlvo = @("Desktop", "Documents", "Downloads", "Pictures", "Videos", "Music", "Favorites")
    $Usuarios = Get-ChildItem -Path $OrigemPath -Directory | Where-Object { 
        $_.Name -notin @("Public", "Default", "All Users", "Default User") 
    }

    foreach ($User in $Usuarios) {
        Write-Host "`n---> Processando Usuario: $($User.Name)" -ForegroundColor Green
        
        foreach ($Pasta in $PastasAlvo) {
            $CaminhoOrigemPasta = Join-Path -Path $User.FullName -ChildPath $Pasta
            $CaminhoDestinoPasta = Join-Path -Path "$DestinoPath\$($User.Name)" -ChildPath $Pasta

            if (Test-Path $CaminhoOrigemPasta) {
                Write-Host "  -> Copiando $Pasta..." -ForegroundColor Gray
                # Multithread ultra rapido
                robocopy $CaminhoOrigemPasta $CaminhoDestinoPasta /E /R:1 /W:1 /MT:8 /XJ /NP | Out-Null
            }
        }
    }

    Write-Host ""
    Write-Host "********************************************************************************" -ForegroundColor Green
    Write-Host "                   BACKUP CONCLUIDO COM SUCESSO!                                " -ForegroundColor Green
    Write-Host "Local salvo: $DestinoPath" -ForegroundColor White
    Write-Host "********************************************************************************" -ForegroundColor Green
    Write-Host ""
    Pause
}