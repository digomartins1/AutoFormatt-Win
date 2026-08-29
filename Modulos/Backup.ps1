<#
==================================================================
  MODULO AUTOBACKUP-WIN (CORRIGIDO E OTIMIZADO)
==================================================================
#>

function Obter-DispositivoUSB {
    # 1. Tenta detectar por barramento fisico USB (HDs Externos e SSDs USB)
    $DiscosUSB = Get-Disk -ErrorAction SilentlyContinue | Where-Object { $_.BusType -eq 'USB' } | Get-Partition | Get-Volume | Where-Object { $_.DriveLetter }
    if ($DiscosUSB) {
        return "$($DiscosUSB[0].DriveLetter):"
    }

    # 2. Fallback para Pendrives tradicionais (DriveType 2)
    $Pendrives = Get-CimInstance Win32_LogicalDisk -ErrorAction SilentlyContinue | Where-Object { $_.DriveType -eq 2 }
    if ($Pendrives) {
        return $Pendrives[0].DeviceID
    }

    return $null
}

function Iniciar-AutoBackup {
    Clear-Host
    Write-Host "********************************************************************************" -ForegroundColor Cyan
    Write-Host "                     ** FERRAMENTA AUTOBACKUP-WIN **                            " -ForegroundColor Yellow
    Write-Host "********************************************************************************" -ForegroundColor Cyan
    Write-Host ""

    $Destino = Obter-DispositivoUSB

    if (-not $Destino) {
        Write-Host "[ALERTA] NENHUM DISPOSITIVO USB DETECTADO!" -ForegroundColor Red
        Write-Host "Conecte um Pendrive ou HD Externo para salvar o backup." -ForegroundColor Yellow
        Write-Host ""
        $tentarManual = Read-Host "Deseja digitar a letra da unidade manualmente? (S/N)"
        if ($tentarManual -ne 'S' -and $tentarManual -ne 's') {
            Write-Host "`nOperacao cancelada para protecao dos dados." -ForegroundColor Cyan
            Pause
            return
        }
        $Destino = Read-Host "Digite a letra da unidade (ex: D ou E)"
        $Destino = "$($Destino.TrimEnd(':\')):"
    } else {
        Write-Host "[OK] Dispositivo USB detectado na unidade: $Destino" -ForegroundColor Green
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

    Write-Host "`nIniciando Backup para o dispositivo em: $DestinoPath" -ForegroundColor Cyan
    Write-Host "--------------------------------------------------------" -ForegroundColor DarkGray

    $PastasAlvo = @("Desktop", "Documents", "Downloads", "Pictures", "Videos", "Music", "Favorites")
    $Usuarios = Get-ChildItem -Path $OrigemPath -Directory | Where-Object { 
        $_.Name -notin @("Public", "Default", "All Users", "Default User") 
    }

    $HouveErros = $false

    foreach ($User in $Usuarios) {
        Write-Host "`n---> Processando Usuario: $($User.Name)" -ForegroundColor Green
        
        foreach ($Pasta in $PastasAlvo) {
            $CaminhoOrigemPasta = Join-Path -Path $User.FullName -ChildPath $Pasta
            $CaminhoDestinoPasta = Join-Path -Path "$DestinoPath\$($User.Name)" -ChildPath $Pasta

            if (Test-Path $CaminhoOrigemPasta) {
                Write-Host "  -> Copiando $Pasta..." -ForegroundColor Gray
                # Multithread ultra rapido com exclusao de junctions (/XJ)
                robocopy $CaminhoOrigemPasta $CaminhoDestinoPasta /E /R:1 /W:1 /MT:8 /XJ /NP | Out-Null
                
                if ($LASTEXITCODE -ge 8) {
                    Write-Host "     [ALERTA] Alguns arquivos de '$Pasta' nao puderam ser copiados." -ForegroundColor Yellow
                    $HouveErros = $true
                }
            }
        }
    }

    Write-Host ""
    Write-Host "********************************************************************************" -ForegroundColor Green
    if ($HouveErros) {
        Write-Host "         BACKUP CONCLUIDO COM ALGUNS AVISOS (VERIFIQUE OS DADOS)                " -ForegroundColor Yellow
    } else {
        Write-Host "                   BACKUP CONCLUIDO COM SUCESSO!                                " -ForegroundColor Green
    }
    Write-Host "Local salvo: $DestinoPath" -ForegroundColor White
    Write-Host "********************************************************************************" -ForegroundColor Green
    Write-Host ""
    Pause
}