<#
==================================================================
  MODULO DE DEPLOY E INSTALACAO AUTOMATIZADA (UEFI / GPT)
==================================================================
#>

function Localizar-ArquivoImagem {
    param ([string]$NomePasta)
    
    $PastasBusca = @(
        "$PSScriptRoot\..\Imagens\$NomePasta",
        "$PSScriptRoot\Imagens\$NomePasta",
        "C:\Imagens\$NomePasta"
    )

    $DiscosUSB = Get-Disk -ErrorAction SilentlyContinue | Where-Object { $_.BusType -eq 'USB' } | Get-Partition | Get-Volume | Where-Object { $_.DriveLetter }
    foreach ($d in $DiscosUSB) {
        $PastasBusca += "$($d.DriveLetter):\Imagens\$NomePasta"
        $PastasBusca += "$($d.DriveLetter):\$NomePasta"
    }

    foreach ($pasta in $PastasBusca) {
        if (Test-Path $pasta) {
            $arquivo = Get-ChildItem -Path $pasta -Include @("*.wim", "*.esd", "*.iso") -Recurse -File | Select-Object -First 1
            if ($arquivo) { return $arquivo.FullName }
        }
    }

    return $null
}

function Iniciar-DeployWindows {
    param (
        [string]$Titulo,
        [string]$NomePastaPadrao,
        [bool]$BypassRequisitosWin11 = $false
    )

    Clear-Host
    Write-Host "================================================================================" -ForegroundColor Cyan
    Write-Host "                INSTALADOR AUTOMATIZADO: $Titulo                                " -ForegroundColor Yellow
    Write-Host "================================================================================" -ForegroundColor Cyan
    Write-Host ""

    # 1. LOCALIZAR ARQUIVO DE IMAGEM
    Write-Host "[1/5] Localizando arquivo de instalacao..." -ForegroundColor Gray
    $CaminhoImagem = Localizar-ArquivoImagem -NomePasta $NomePastaPadrao
    $MontouIso = $false
    $DriveIso = $null

    if (-not $CaminhoImagem) {
        Write-Host "[AVISO] Nenhuma imagem encontrada automaticamente em 'Imagens\$NomePastaPadrao'." -ForegroundColor Yellow
        $CaminhoImagem = Read-Host "Digite o caminho completo do arquivo (.wim, .esd ou .iso)"
    }

    if (-not (Test-Path $CaminhoImagem)) {
        Write-Host "`n[ERRO] Arquivo nao encontrado: $CaminhoImagem" -ForegroundColor Red
        Pause
        return
    }

    if ($CaminhoImagem.EndsWith(".iso", [System.StringComparison]::OrdinalIgnoreCase)) {
        Write-Host "  -> Montando arquivo ISO..." -ForegroundColor Gray
        $IsoMontada = Mount-DiskImage -ImagePath $CaminhoImagem -PassThru
        $DriveIso = ($IsoMontada | Get-Volume).DriveLetter + ":"
        $MontouIso = $true

        if (Test-Path "$DriveIso\sources\install.wim") {
            $CaminhoWim = "$DriveIso\sources\install.wim"
        } elseif (Test-Path "$DriveIso\sources\install.esd") {
            $CaminhoWim = "$DriveIso\sources\install.esd"
        } else {
            Write-Host "`n[ERRO] Nao foi encontrado install.wim/esd dentro da ISO montada!" -ForegroundColor Red
            Dismount-DiskImage -ImagePath $CaminhoImagem | Out-Null
            Pause
            return
        }
    } else {
        $CaminhoWim = $CaminhoImagem
    }

    Write-Host "  -> Imagem carregada: $CaminhoWim" -ForegroundColor Green

    # 2. SELECAO DO DISCO DE DESTINO
    Write-Host "`n[2/5] Selecione o disco de destino:" -ForegroundColor Gray
    Get-Disk | Format-Table Number, FriendlyName, @{Label="Tamanho (GB)"; Expression={[int]($_.Size / 1GB)}}, BusType, PartitionStyle -AutoSize

    $DiscoNum = Read-Host "Digite o NUMERO do disco onde o Windows sera instalado (Ex: 0)"
    $DiscoAlvo = Get-Disk -Number $DiscoNum -ErrorAction SilentlyContinue

    if (-not $DiscoAlvo) {
        Write-Host "`n[ERRO] Disco invalido selecionado!" -ForegroundColor Red
        if ($MontouIso) { Dismount-DiskImage -ImagePath $CaminhoImagem | Out-Null }
        Pause
        return
    }

    Write-Host "`n********************************************************************************" -ForegroundColor Red
    Write-Host " [ALERTA MAXIMO] TODOS OS DADOS DO DISCO $DiscoNum ($($DiscoAlvo.FriendlyName)) SERAO APAGADOS!" -ForegroundColor Red
    Write-Host "********************************************************************************" -ForegroundColor Red
    $confirma = Read-Host "Digite SIM para formatar e continuar"
    if ($confirma -ne "SIM") {
        Write-Host "`nOperacao cancelada pelo usuario." -ForegroundColor Cyan
        if ($MontouIso) { Dismount-DiskImage -ImagePath $CaminhoImagem | Out-Null }
        Pause
        return
    }

    # 3. SELECAO DA EDICAO
    Write-Host "`n[3/5] Edicoes disponiveis dentro da imagem:" -ForegroundColor Gray
    $Edicoes = Get-WindowsImage -ImagePath $CaminhoWim
    $Edicoes | Format-Table ImageIndex, ImageName, @{Label="Tamanho (GB)"; Expression={[math]::Round($_.ImageSize / 1GB, 2)}} -AutoSize

    $IndexEscolhido = Read-Host "Digite o INDEX da edicao desejada (padrao: 1)"
    if ([string]::IsNullOrWhiteSpace($IndexEscolhido)) { $IndexEscolhido = "1" }

    # 4. PARTICIONAMENTO GPT / UEFI
    Write-Host "`n[4/5] Preparando particoes GPT/UEFI no Disco $DiscoNum..." -ForegroundColor Yellow
    try {
        Clear-Disk -Number $DiscoNum -RemoveData -RemoveOEM -Confirm:$false
        Initialize-Disk -Number $DiscoNum -PartitionStyle GPT

        # EFI Boot (100MB FAT32)
        $PartEFI = New-Partition -DiskNumber $DiscoNum -Size 100MB -GptType "{c12a7328-f81f-11d2-ba4b-00a0c93ec93b}"
        Format-Volume -Partition $PartEFI -FileSystem FAT32 -NewFileSystemLabel "System" | Out-Null
        
        # MSR (16MB)
        New-Partition -DiskNumber $DiscoNum -Size 16MB -GptType "{e3c9e316-0b5c-4db8-817d-f92df00215ae}" | Out-Null

        # Particao Windows (Restante em NTFS)
        $PartWin = New-Partition -DiskNumber $DiscoNum -UseMaximumSize -AssignDriveLetter
        Format-Volume -Partition $PartWin -FileSystem NTFS -NewFileSystemLabel "Windows" | Out-Null
        $LetraWin = "$($PartWin.DriveLetter):"
    } catch {
        Write-Host "`n[ERRO] Falha no particionamento do disco: $($_.Exception.Message)" -ForegroundColor Red
        if ($MontouIso) { Dismount-DiskImage -ImagePath $CaminhoImagem | Out-Null }
        Pause
        return
    }

    # 5. APLICACAO DA IMAGEM E CONFIGURACOES
    Write-Host "`n[5/5] Aplicando imagem do sistema na unidade $LetraWin (Aguarde alguns minutos)..." -ForegroundColor Yellow
    dism.exe /Apply-Image /ImageFile:$CaminhoWim /Index:$IndexEscolhido /ApplyDir:$LetraWin

    if ($LASTEXITCODE -ne 0) {
        Write-Host "`n[ERRO] Falha ao descompactar a imagem com o DISM!" -ForegroundColor Red
        if ($MontouIso) { Dismount-DiskImage -ImagePath $CaminhoImagem | Out-Null }
        Pause
        return
    }

    # Bootloader UEFI
    Write-Host "  -> Gravando arquivos de inicializacao UEFI (BCDBoot)..." -ForegroundColor Gray
    bcdboot.exe "$LetraWin\Windows" /s "$LetraWin" /f ALL | Out-Null

    # Bypass de requisitos do Windows 11
    if ($BypassRequisitosWin11) {
        Write-Host "  -> Aplicando bypass de requisitos do Windows 11 (TPM / RAM / Conta MS)..." -ForegroundColor Green
        $RegPath = "$LetraWin\Windows\System32\config\SYSTEM"
        if (Test-Path $RegPath) {
            reg load HKLM\TEMP_SYSTEM $RegPath | Out-Null
            New-Item -Path "HKLM:\TEMP_SYSTEM\Setup\LabConfig" -Force | Out-Null
            Set-ItemProperty -Path "HKLM:\TEMP_SYSTEM\Setup\LabConfig" -Name "BypassTPMCheck" -Value 1 -Type DWord
            Set-ItemProperty -Path "HKLM:\TEMP_SYSTEM\Setup\LabConfig" -Name "BypassSecureBootCheck" -Value 1 -Type DWord
            Set-ItemProperty -Path "HKLM:\TEMP_SYSTEM\Setup\LabConfig" -Name "BypassRAMCheck" -Value 1 -Type DWord
            Set-ItemProperty -Path "HKLM:\TEMP_SYSTEM\Setup\LabConfig" -Name "BypassCPUCheck" -Value 1 -Type DWord
            Set-ItemProperty -Path "HKLM:\TEMP_SYSTEM\Setup\LabConfig" -Name "BypassStorageCheck" -Value 1 -Type DWord
            reg unload HKLM\TEMP_SYSTEM | Out-Null
        }
    }

    if ($MontouIso) {
        Dismount-DiskImage -ImagePath $CaminhoImagem | Out-Null
    }

    Write-Host ""
    Write-Host "********************************************************************************" -ForegroundColor Green
    Write-Host "              DEPLOY CONCLUIDO COM SUCESSO NO DISCO $DiscoNum!                   " -ForegroundColor Green
    Write-Host "   Remova o pendrive e reinicie o PC para iniciar a configuracao inicial.       " -ForegroundColor White
    Write-Host "********************************************************************************" -ForegroundColor Green
    Write-Host ""
    Pause
}