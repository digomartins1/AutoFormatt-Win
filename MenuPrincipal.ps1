<#
==============================================================================
  AUTOFORMATT-WIN GOLD V2.0 - SCRIPT PRINCIPAL & INTERFACE RESPONSIVA
==============================================================================
#>

# Carrega todos os modulos se estiver rodando localmente
if (Test-Path "$PSScriptRoot\Modulos\Backup.ps1")    { . "$PSScriptRoot\Modulos\Backup.ps1" }
if (Test-Path "$PSScriptRoot\Modulos\Manutencao.ps1"){ . "$PSScriptRoot\Modulos\Manutencao.ps1" }
if (Test-Path "$PSScriptRoot\Modulos\Deploy.ps1")    { . "$PSScriptRoot\Modulos\Deploy.ps1" }
if (Test-Path "$PSScriptRoot\Modulos\Captura.ps1")   { . "$PSScriptRoot\Modulos\Captura.ps1" }

# 1. TAMANHO INICIAL PADRAO (JANELA NO CENTRO DO MONITOR)
$CodigoCsharp = @"
using System;
using System.Runtime.InteropServices;

public class AjustarJanela {
    [DllImport("user32.dll")]
    public static extern bool MoveWindow(IntPtr hWnd, int X, int Y, int nWidth, int nHeight, bool bRepaint);
    
    [DllImport("user32.dll")]
    public static extern int GetSystemMetrics(int nIndex);
}
"@

try {
    Add-Type -TypeDefinition $CodigoCsharp -ErrorAction SilentlyContinue
    $hwnd = (Get-Process -Id $PID).MainWindowHandle
    if ($hwnd -ne [IntPtr]::Zero) {
        $LarguraJanela = 780
        $AlturaJanela = 690
        
        $TelaLargura = [AjustarJanela]::GetSystemMetrics(0)
        $TelaAltura  = [AjustarJanela]::GetSystemMetrics(1)
        
        $PosX = [int](($TelaLargura - $LarguraJanela) / 2)
        $PosY = [int](($TelaAltura - $AlturaJanela) / 2)
        
        [AjustarJanela]::MoveWindow($hwnd, $PosX, $PosY, $LarguraJanela, $AlturaJanela, $true) | Out-Null
    }
} catch {}

# 2. CONFIGURACOES VISUAIS E PROTOCOLO
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls13
[Console]::OutputEncoding = [System.Text.Encoding]::ASCII
$OutputEncoding = [System.Text.Encoding]::ASCII
$Host.UI.RawUI.WindowTitle = "AutoFormatt-Win GOLD V2.0"
$Host.UI.RawUI.BackgroundColor = "Black"
$Host.UI.RawUI.ForegroundColor = "White"
Clear-Host

# 3. VERIFICACAO DE ADMINISTRADOR
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "[ERRO] Execute o script como Administrador!" -ForegroundColor Red
    Pause
    exit
}

# 4. FUNCOES VISUAIS
function Obter-LarguraAtual {
    $largura = [Console]::WindowWidth
    if ($largura -lt 75) { return 75 }
    return $largura
}

function Escrever-Centro {
    param (
        [string]$Texto,
        [ConsoleColor]$Cor = [ConsoleColor]::White
    )
    $Largura = Obter-LarguraAtual
    $Espacos = [Math]::Max(0, [int](($Largura - $Texto.Length) / 2))
    $Padding = " " * $Espacos
    Write-Host "$Padding$Texto" -ForegroundColor $Cor
}

function Desenhar-Banner {
    $Banner = @(
        "    _         _         _____                               _     _   ",
        "   / \  _   _| |_ ___  |  ___|__  _ __ _ __ ___   __ _  ___| |__ | |_ ",
        "  / _ \| | | | __/ _ \ | |_ / _ \| '__| '_ ` _ \ / _` |/ __| '_ \| __|",
        " / ___ \ |_| | || (_) ||  _| (_) | |  | | | | | | (_| | (__| | | | |_ ",
        "/_/   \_\__,_|\__\___/ |_|  \___/|_|  |_| |_| |_|\__,_|\___|_| |_|\__|"
    )

    foreach ($linhaBanner in $Banner) {
        Escrever-Centro $linhaBanner Cyan
    }
    Escrever-Centro ">> AUTOFORMATT-WIN GOLD V2.0 PRO <<" Yellow
    Escrever-Centro "Criado por: Rodrigo Martins (@digomartinss) | github.com/digomartins1" DarkGray
}

function Mostrar-ManualUso {
    Clear-Host
    $Largura = Obter-LarguraAtual
    $Linha = "*" * ($Largura - 2)

    Write-Host $Linha -ForegroundColor Cyan
    Escrever-Centro "** MANUAL DE USO E GUIA DO TECNICO **" Yellow
    Write-Host $Linha -ForegroundColor Cyan
    Write-Host ""
    Write-Host " [ 1 ] INSTALACOES AUTOMATIZADAS [ 1 / 2 ]:" -ForegroundColor Cyan
    Write-Host "       -> Suporta Windows 10 e Windows 11 (com bypass de TPM/Conta MS)." -ForegroundColor White
    Write-Host "       -> Coloque os arquivos dentro de 'Imagens\Win10' ou 'Imagens\Win11'." -ForegroundColor White
    Write-Host ""
    Write-Host " [ 2 ] AUTO CAPTURA DE IMAGEM [ A ]:" -ForegroundColor Cyan
    Write-Host "       -> Captura um Windows ja instalado e cria um .WIM bootavel." -ForegroundColor White
    Write-Host ""
    Write-Host " [ 3 ] BACKUP E MANUTENCAO [ B / F ]:" -ForegroundColor Cyan
    Write-Host "       -> Backup rapido de usuarios e reparo completo do sistema." -ForegroundColor White
    Write-Host ""
    Write-Host $Linha -ForegroundColor Cyan
    Write-Host ""
    Pause
}

function Mostrar-MenuPrincipal {
    Clear-Host

    $Largura = Obter-LarguraAtual
    $Linha = "*" * ($Largura - 2)

    Write-Host $Linha -ForegroundColor Cyan
    Desenhar-Banner
    Write-Host $Linha -ForegroundColor Cyan
    Write-Host ""
    
    # Secao 1: Deploy
    Escrever-Centro "**Ferramenta AutoFormatt-Win GOLD**" Yellow
    Write-Host ""
    Escrever-Centro "[ 1 ] Windows 10        [ 2 ] Windows 11" White
    Write-Host ""
    Write-Host $Linha -ForegroundColor DarkGray
    Write-Host ""
    
    # Secao 2: Captura
    Escrever-Centro "**Ferramenta Auto-Capture-Image**" Yellow
    Write-Host ""
    Escrever-Centro "[ A ] Auto-Capture-Image" White
    Write-Host ""
    Write-Host $Linha -ForegroundColor DarkGray
    Write-Host ""
    
    # Secao 3: Backup
    Escrever-Centro "**Ferramenta de Auto Backup**" Yellow
    Write-Host ""
    Escrever-Centro "[ B ] Ferramenta AutoBackup-Win" White
    Write-Host ""
    Write-Host $Linha -ForegroundColor DarkGray
    Write-Host ""
    
    # Secao 4: Manutencao
    Escrever-Centro "**Ferramentas para Manutencao**" Yellow
    Write-Host ""
    Escrever-Centro "[ F ] Ferramentas de Manutencao" White
    Write-Host ""
    Write-Host $Linha -ForegroundColor DarkGray
    Write-Host ""
    
    # Secao 5: Navegacao
    Escrever-Centro "[ M ] Manual de uso" White
    Escrever-Centro "[ S ] Sair" White
    Write-Host ""
    Write-Host $Linha -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "Digite a opcao desejada: " -NoNewline
}

function Ler-OpcaoResponsiva {
    $larguraSalva = [Console]::WindowWidth
    $alturaSalva  = [Console]::WindowHeight

    while (-not [Console]::KeyAvailable) {
        $larguraAtual = [Console]::WindowWidth
        $alturaAtual  = [Console]::WindowHeight

        if ($larguraAtual -ne $larguraSalva -or $alturaAtual -ne $alturaSalva) {
            Mostrar-MenuPrincipal
            $larguraSalva = $larguraAtual
            $alturaSalva  = $alturaAtual
        }
        Start-Sleep -Milliseconds 80
    }

    return [Console]::ReadKey($true).KeyChar.ToString()
}

# LOOP PRINCIPAL
do {
    Mostrar-MenuPrincipal
    $opcao = Ler-OpcaoResponsiva
    $opcao = $opcao.ToUpper()

    switch ($opcao) {
        '1' { Iniciar-DeployWindows -Titulo "Windows 10" -NomePastaPadrao "Win10" }
        '2' { Iniciar-DeployWindows -Titulo "Windows 11" -NomePastaPadrao "Win11" -BypassRequisitosWin11 $true }
        'A' { Iniciar-CapturaImagem }
        'B' { Iniciar-AutoBackup }
        'F' { Iniciar-Manutencao }
        'M' { Mostrar-ManualUso }
        'S' { 
            Write-Host "`nSaindo do sistema..." -ForegroundColor Cyan
            Start-Sleep -Seconds 1
            break 
        }
        Default {}
    }
} while ($opcao -ne 'S')