<#
==================================================================
  MODULO DE MANUTENCAO, REPARO E DRIVERS - PRO
==================================================================
#>

function Mostrar-MenuManutencao {
    Clear-Host
    Write-Host "********************************************************************************" -ForegroundColor Cyan
    Write-Host "                     ** FERRAMENTAS DE MANUTENCAO **                            " -ForegroundColor Yellow
    Write-Host "********************************************************************************" -ForegroundColor Cyan
    Write-Host ""
    Write-Host " [ 1 ] Fazer Backup de Todos os Drivers do PC" -ForegroundColor White
    Write-Host " [ 2 ] Reparar Arquivos Corrompidos do Windows (SFC + DISM)" -ForegroundColor White
    Write-Host " [ 3 ] Verificar Integridade do Disco (CHKDSK)" -ForegroundColor White
    Write-Host " [ 4 ] Limpeza Profunda (Cache Windows Update + Temporarios)" -ForegroundColor White
    Write-Host " [ 5 ] Ativar Conta de Administrador Oculta / Resetar Senha" -ForegroundColor White
    Write-Host " [ 6 ] Verificar Saude do SSD / HD (Status SMART)" -ForegroundColor White
    Write-Host "********************************************************************************" -ForegroundColor DarkGray
    Write-Host " [ 0 ] Voltar ao Menu Principal" -ForegroundColor White
    Write-Host "********************************************************************************" -ForegroundColor DarkGray
    Write-Host ""
}

function Iniciar-Manutencao {
    do {
        Mostrar-MenuManutencao
        $escolha = Read-Host "Digite a opcao desejada"

        switch ($escolha) {
            '1' { Backup-Drivers }
            '2' { Reparar-Sistema }
            '3' { Verificar-Disco }
            '4' { Limpeza-Profunda }
            '5' { Gerenciar-Admin }
            '6' { Testar-SaudeDisco }
            '0' { break }
            Default { 
                Write-Host "`nOpcao Invalida!" -ForegroundColor Red
                Start-Sleep -Seconds 1 
            }
        }
    } while ($escolha -ne '0')
}

# 1. BACKUP DE DRIVERS
function Backup-Drivers {
    Clear-Host
    Write-Host "--- BACKUP DE DRIVERS DO SISTEMA ---" -ForegroundColor Green
    
    $Pendrives = Get-CimInstance Win32_LogicalDisk | Where-Object { $_.DriveType -eq 2 }
    if ($Pendrives) {
        $Destino = "$($Pendrives[0].DeviceID)\Drivers_Backup\$env:COMPUTERNAME"
    } else {
        $Destino = "C:\Drivers_Backup_$env:COMPUTERNAME"
    }

    Write-Host "Exportando drivers para: $Destino" -ForegroundColor Yellow
    if (-not (Test-Path $Destino)) { New-Item -Path $Destino -ItemType Directory -Force | Out-Null }

    Export-WindowsDriver -Online -Destination $Destino
    Write-Host "`n[OK] Drivers exportados com sucesso!" -ForegroundColor Green
    Write-Host ""
    Pause
}

# 2. REPARO DE SISTEMA
function Reparar-Sistema {
    Clear-Host
    Write-Host "--- REPARACAO DO WINDOWS ---" -ForegroundColor Green
    Write-Host "[1/2] Executando DISM RestoreHealth (Reparando imagem base)..." -ForegroundColor Yellow
    dism.exe /Online /Cleanup-Image /RestoreHealth

    Write-Host "`n[2/2] Executando Verificador de Arquivos do Sistema (SFC)..." -ForegroundColor Yellow
    sfc /scannow

    Write-Host "`n[OK] Verificacao e reparo finalizados!" -ForegroundColor Green
    Write-Host ""
    Pause
}

# 3. VERIFICACAO DE DISCO
function Verificar-Disco {
    Clear-Host
    Write-Host "--- VERIFICACAO DO SISTEMA DE ARQUIVOS (CHKDSK) ---" -ForegroundColor Green
    Write-Host "Verificando particao C:..." -ForegroundColor Yellow
    chkdsk C: /scan
    Write-Host ""
    Pause
}

# 4. LIMPEZA PROFUNDA
function Limpeza-Profunda {
    Clear-Host
    Write-Host "--- LIMPEZA PROFUNDA DO SISTEMA ---" -ForegroundColor Green
    
    Write-Host "Parando servico do Windows Update..." -ForegroundColor Gray
    Stop-Service -Name wuauserv -Force -ErrorAction SilentlyContinue
    
    Write-Host "Limpando arquivos de atualizacoes antigas..." -ForegroundColor Yellow
    Remove-Item -Path "$env:SystemRoot\SoftwareDistribution\Download\*" -Recurse -Force -ErrorAction SilentlyContinue
    
    Write-Host "Reiniciando servico do Windows Update..." -ForegroundColor Gray
    Start-Service -Name wuauserv -ErrorAction SilentlyContinue

    Write-Host "Limpando arquivos temporarios..." -ForegroundColor Yellow
    Remove-Item -Path "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "C:\Windows\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue

    Write-Host "`n[OK] Limpeza concluida com sucesso!" -ForegroundColor Green
    Write-Host ""
    Pause
}

# 5. GERENCIAR ADMIN / SENHA
function Gerenciar-Admin {
    Clear-Host
    Write-Host "--- GERENCIAMENTO DE CONTA ADMINISTRADOR ---" -ForegroundColor Green
    Write-Host "1 - Ativar a conta oculta 'Administrador'"
    Write-Host "2 - Redefinir a senha de um usuario local"
    Write-Host ""
    $subOpcao = Read-Host "Digite a opcao desejada"

    if ($subOpcao -eq '1') {
        net user Administrador /active:yes
        Write-Host "`n[OK] A conta 'Administrador' foi ativada!" -ForegroundColor Green
    } elseif ($subOpcao -eq '2') {
        Write-Host "`nUsuarios locais encontrados:" -ForegroundColor Cyan
        Get-LocalUser | Format-Table Name, Enabled, LastLogon -AutoSize
        
        $UsuarioAlvo = Read-Host "Digite o nome do usuario para alterar a senha"
        $NovaSenha = Read-Host "Digite a nova senha"
        
        net user $UsuarioAlvo $NovaSenha
        Write-Host "`n[OK] Senha de '$UsuarioAlvo' redefinida com sucesso!" -ForegroundColor Green
    }
    Write-Host ""
    Pause
}

# 6. STATUS DE SAUDE DO DISCO (SMART)
function Testar-SaudeDisco {
    Clear-Host
    Write-Host "--- STATUS DE SAUDE DOS DISCOS (SMART) ---" -ForegroundColor Green
    Get-PhysicalDisk | Format-Table DeviceId, FriendlyName, MediaType, OperationalStatus, HealthStatus -AutoSize
    Write-Host ""
    Pause
}