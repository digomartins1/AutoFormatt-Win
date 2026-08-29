# ==============================================================================
# CARREGADOR 100% EM MEMORIA RAM COM TODOS OS MODULOS
# ==============================================================================
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls13

$Usuario = "digomartins1"
$Repo    = "AutoFormatt-Win"
$Branch  = "main"
$Cache   = (Get-Date).Ticks

$BaseUrl = "https://raw.githubusercontent.com/$Usuario/$Repo/$Branch"

# Lista de modulos completos que serao carregados na RAM
$Arquivos = @(
    "$BaseUrl/Modulos/Backup.ps1?v=$Cache",
    "$BaseUrl/Modulos/Manutencao.ps1?v=$Cache",
    "$BaseUrl/Modulos/Deploy.ps1?v=$Cache",
    "$BaseUrl/Modulos/Captura.ps1?v=$Cache",
    "$BaseUrl/MenuPrincipal.ps1?v=$Cache"
)

Write-Host "Carregando suite completa para a memoria RAM..." -ForegroundColor Cyan

$ScriptCompletoNaRAM = ($Arquivos | ForEach-Object { 
    Invoke-RestMethod -Uri $_ -UseBasicParsing 
}) -join "`n"

Invoke-Expression $ScriptCompletoNaRAM