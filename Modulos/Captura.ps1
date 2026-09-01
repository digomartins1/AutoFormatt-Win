<#
==================================================================
  MODULO AUTO-CAPTURE-IMAGE (CRIACAO DE IMAGENS WIM PERSONALIZADAS)
==================================================================
#>

function Iniciar-CapturaImagem {
    Clear-Host
    Write-Host "********************************************************************************" -ForegroundColor Cyan
    Write-Host "                     ** AUTO-CAPTURE-IMAGE (WIM) **                             " -ForegroundColor Yellow
    Write-Host "********************************************************************************" -ForegroundColor Cyan
    Write-Host ""

    Write-Host "Particoes disponiveis no sistema:" -ForegroundColor Cyan
    Get-Volume | Where-Object { $_.DriveLetter -and $_.DriveType -eq 'Fixed' } | Format-Table DriveLetter, FileSystemLabel, @{Label="Espaco Usado (GB)"; Expression={[math]::Round(($_.Size - $_.SizeRemaining)/1GB, 2)}}, @{Label="Espaco Livre (GB)"; Expression={[math]::Round($_.SizeRemaining/1GB, 2)}} -AutoSize

    $OrigemLetra = Read-Host "Digite a LETRA da particao do Windows que deseja capturar (Ex: C ou D)"
    $OrigemPath = "$($OrigemLetra.TrimEnd(':\')):"

    if (-not (Test-Path "$OrigemPath\Windows")) {
        Write-Host "`n[ERRO] Nao foi encontrada uma instalacao do Windows em $OrigemPath!" -ForegroundColor Red
        Pause
        return
    }

    # Busca destino (Pendrive ou HD Externo)
    $DiscosUSB = @(Get-Disk -ErrorAction SilentlyContinue | Where-Object { $_.BusType -eq 'USB' } | Get-Partition | Get-Volume | Where-Object { $_.DriveLetter })
    if ($DiscosUSB.Count -gt 0) {
        $DestinoLetra = "$($DiscosUSB[0].DriveLetter):"
    } else {
        Write-Host "`n[AVISO] Nenhum pendrive/disco externo detectado automaticamente." -ForegroundColor Yellow
        $DestinoLetra = Read-Host "Digite a letra do disco de DESTINO para salvar o WIM (ex: D: ou E:)"
        $DestinoLetra = "$($DestinoLetra.TrimEnd(':\')):"
    }

    # Protecao contra auto-captura (origem == destino)
    if ($DestinoLetra.ToUpper() -eq $OrigemPath.ToUpper()) {
        Write-Host "`n[ERRO] O disco de destino ($DestinoLetra) nao pode ser o mesmo disco de origem da captura!" -ForegroundColor Red
        Write-Host "Salve a imagem em um Pendrive ou em outra particao separada." -ForegroundColor Yellow
        Pause
        return
    }

    $NomeImagem = Read-Host "`nDigite o nome da imagem (Ex: Windows10_Customizado)"
    if ([string]::IsNullOrWhiteSpace($NomeImagem)) { $NomeImagem = "Windows_Custom_$env:COMPUTERNAME" }

    $PastaDestino = "$DestinoLetra\Imagens_Capturadas"
    if (-not (Test-Path $PastaDestino)) { New-Item -Path $PastaDestino -ItemType Directory -Force | Out-Null }

    $ArquivoFinalWim = "$PastaDestino\$NomeImagem.wim"

    Write-Host "`n--------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host "Origem da Captura: $OrigemPath" -ForegroundColor White
    Write-Host "Arquivo de Destino: $ArquivoFinalWim" -ForegroundColor White
    Write-Host "--------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host ""

    $confirma = Read-Host "Deseja iniciar a captura em alta compressao agora? (S/N)"
    if ($confirma -ne 'S' -and $confirma -ne 's') {
        Write-Host "`nCaptura cancelada." -ForegroundColor Cyan
        Pause
        return
    }

    Write-Host "`nCapturando imagem do sistema (Isso pode levar alguns minutos)..." -ForegroundColor Yellow
    
    dism.exe /Capture-Image /ImageFile:$ArquivoFinalWim /CaptureDir:$OrigemPath /Name:$NomeImagem /Description:"Capturado via AutoFormatt-Win" /Compress:max /CheckIntegrity /Verify

    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "********************************************************************************" -ForegroundColor Green
        Write-Host "                   IMAGEM CAPTURADA COM SUCESSO!                                " -ForegroundColor Green
        Write-Host "Arquivo salvo em: $ArquivoFinalWim" -ForegroundColor White
        Write-Host "********************************************************************************" -ForegroundColor Green
    } else {
        Write-Host "`n[ERRO] Ocorreu um problema durante o processo de captura!" -ForegroundColor Red
    }
    
    Write-Host ""
    Pause
}