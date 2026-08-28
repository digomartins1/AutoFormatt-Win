# ==============================================================================
# 1. TAMANHO INICIAL PADRAO (JANELA COMPACTA NO CENTRO)
# ==============================================================================
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

# ==============================================================================
# 2. CONFIGURACOES VISUAIS
# ==============================================================================
[Console]::OutputEncoding = [System.Text.Encoding]::ASCII
$OutputEncoding = [System.Text.Encoding]::ASCII
$Host.UI.RawUI.WindowTitle = "AutoFormatt-Win GOLD V2.0"
$Host.UI.RawUI.BackgroundColor = "Black"
$Host.UI.RawUI.ForegroundColor = "White"
Clear-Host

# ==============================================================================
# 3. VERIFICACAO DE ADMINISTRADOR
# ==============================================================================
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "[ERRO] Execute o script como Administrador!" -ForegroundColor Red
    Pause
    exit
}

# ==============================================================================
# 4. IMPORTACAO DOS MODULOS (SUPORTE LOCAL + NUVEM / GITHUB)
# ==============================================================================
# COLOQUE AQUI OS SEUS DADOS DO GITHUB:
$MeuUsuarioGithub = "SEU-USUARIO"
$MeuRepositorio   = "AutoFormatt-Win"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# 1. Se estiver rodando no Pendrive/Disco Local
if ($ScriptDir -and (Test-Path "$ScriptDir\Modulos\Backup.ps1")) {
    . "$ScriptDir\Modulos\Backup.ps1"
    . "$ScriptDir\Modulos\Manutencao.ps1"
} 
# 2. Se estiver rodando via comando 'irm | iex' da Nuvem
else {
    $BaseUrl = "https://raw.githubusercontent.com/$MeuUsuarioGithub/$MeuRepositorio/main/Modulos"
    try {
        irm "$BaseUrl/Backup.ps1" | iex
        irm "$BaseUrl/Manutencao.ps1" | iex
    } catch {
        Write-Host "[AVISO] Modulos da nuvem nao puderam ser carregados." -ForegroundColor Yellow
    }
}

# ==============================================================================
# 5. FUNCOES DE CALCULO DINAMICO E CENTRALIZACAO
# ==============================================================================
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

# ==============================================================================
# 6. BANNER EM ASCII ART
# ==============================================================================
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
    Escrever-Centro "Criado por: Seu Nome (@seu.usuario) | github.com/$MeuUsuarioGithub" DarkGray
}

# ==============================================================================
# 7. TELA DO MANUAL DE USO (OPÇÃO M)
# ==============================================================================
function Mostrar-ManualUso {
    Clear-Host
    $Largura = Obter-LarguraAtual
    $Linha = "*" * ($Largura - 2)

    Write-Host $Linha -ForegroundColor Cyan
    Escrever-Centro "** MANUAL DE USO E GUIA DO TECNICO **" Yellow
    Write-Host $Linha -ForegroundColor Cyan
    Write-Host ""
    
    Write-Host " [ 1 ] CONTROLES E NAVEGACAO:" -ForegroundColor Cyan
    Write-Host "       -> Pressione a tecla da opcao desejada para abrir instantaneamente." -ForegroundColor White
    Write-Host "       -> A janela e responsiva: redimensione ou maximize a qualquer momento." -ForegroundColor White
    Write-Host ""
    
    Write-Host " [ 2 ] FERRAMENTAS AUTOFORMATT [ 1 ] A [ 4 ]:" -ForegroundColor Cyan
    Write-Host "       -> [ 1 ] Windows 10 Pro       [ 2 ] Windows 11 Pro" -ForegroundColor White
    Write-Host "       -> [ 3 ] Windows Server       [ 4 ] Versao Gamer Otimizada" -ForegroundColor White
    Write-Host ""

    Write-Host " [ 3 ] FERRAMENTA AUTOBACKUP-WIN [ B ]:" -ForegroundColor Cyan
    Write-Host "       -> Detecta pendrives ou HDs externos conectados automaticamente." -ForegroundColor White
    Write-Host "       -> Copia: Desktop, Documentos, Downloads, Imagens, Videos e Musicas." -ForegroundColor White
    Write-Host "       -> Possui trava que impede salvar no disco C: para evitar perdas." -ForegroundColor White
    Write-Host ""
    
    Write-Host " [ 4 ] CENTRAL DE MANUTENCAO [ F ]:" -ForegroundColor Cyan
    Write-Host "       -> [ 1 ] Backup Drivers: Salva todos os drivers de rede, video e audio." -ForegroundColor White
    Write-Host "       -> [ 2 ] Reparo SFC/DISM: Corrige erros de tela azul e arquivos corrompidos." -ForegroundColor White
    Write-Host "       -> [ 3 ] CHKDSK: Varre a particao do sistema em busca de falhas no disco." -ForegroundColor White
    Write-Host "       -> [ 4 ] Limpeza: Remove gigabytes de cache travado do Windows Update." -ForegroundColor White
    Write-Host "       -> [ 5 ] Admin/Senha: Ativa o Administrador nativo ou troca senhas locais." -ForegroundColor White
    Write-Host "       -> [ 6 ] Saude SMART: Exibe o status fisico e saude do SSD/HD." -ForegroundColor White
    Write-Host ""
    
    Write-Host $Linha -ForegroundColor Cyan
    Write-Host ""
    Pause
}

# ==============================================================================
# 8. DESENHO DO MENU PRINCIPAL
# ==============================================================================
function Mostrar-MenuPrincipal {
    Clear-Host

    $Largura = Obter-LarguraAtual
    $Linha = "*" * ($Largura - 2)

    # Topo com Banner
    Write-Host $Linha -ForegroundColor Cyan
    Desenhar-Banner
    Write-Host $Linha -ForegroundColor Cyan
    Write-Host ""
    
    # Secao 1: Deploy
    Escrever-Centro "**Ferramenta AutoFormatt-Win GOLD**" Yellow
    Write-Host ""
    Escrever-Centro "[ 1 ] Win10        [ 2 ] Win11" White
    Escrever-Centro "[ 3 ] Win-Server    [ 4 ] GamerVersion" White
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

# ==============================================================================
# 9. SENSOR DE REDIMENSIONAMENTO EM TEMPO REAL
# ==============================================================================
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

# ==============================================================================
# 10. LOOP PRINCIPAL
# ==============================================================================
do {
    Mostrar-MenuPrincipal
    $opcao = Ler-OpcaoResponsiva
    $opcao = $opcao.ToUpper()

    switch ($opcao) {
        '1' { Write-Host "`nModulo Windows 10 em desenvolvimento..." -ForegroundColor Yellow; Pause }
        '2' { Write-Host "`nModulo Windows 11 em desenvolvimento..." -ForegroundColor Yellow; Pause }
        '3' { Write-Host "`nModulo Windows Server em desenvolvimento..." -ForegroundColor Yellow; Pause }
        '4' { Write-Host "`nModulo GamerVersion em desenvolvimento..." -ForegroundColor Yellow; Pause }
        'A' { Write-Host "`nModulo de Captura em desenvolvimento..." -ForegroundColor Yellow; Pause }
        'B' { 
            if (Get-Command Iniciar-AutoBackup -ErrorAction SilentlyContinue) { 
                Iniciar-AutoBackup 
            } else { 
                Write-Host "`nModulo Backup.ps1 nao encontrado!" -ForegroundColor Red
                Pause 
            } 
        }
        'F' { 
            if (Get-Command Iniciar-Manutencao -ErrorAction SilentlyContinue) { 
                Iniciar-Manutencao 
            } else { 
                Write-Host "`nModulo Manutencao.ps1 nao encontrado!" -ForegroundColor Red
                Pause 
            } 
        }
        'M' { 
            Mostrar-ManualUso
        }
        'S' { 
            Write-Host "`nSaindo do sistema..." -ForegroundColor Cyan
            Start-Sleep -Seconds 1
            break 
        }
        Default {
            # Ignora teclas aleatorias
        }
    }
} while ($opcao -ne 'S')