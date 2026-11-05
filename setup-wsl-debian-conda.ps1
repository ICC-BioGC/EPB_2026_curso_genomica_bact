<#
.SYNOPSIS
    Instala o WSL com Debian no Windows 10/11, atualiza o sistema, instala e configura o Git,
    instala o Miniforge (Conda/Mamba), cria multiplos ambientes de bioinformatica isolados
    e baixa/indexa os bancos de dados necessarios (RGI/CARD, MOB-suite, Prokka, BUSCO e MLST).
.NOTES
    Execute este script como Administrador no PowerShell.
#>

# ==============================================================================
# [PERSONALIZACAO] PARAMETROS CONFIGURAVEIS PELO USUARIO
# ==============================================================================

# 1. Nome da distribuicao WSL (Padrao: Debian)
$DistroName = "Debian"

# 2. Usuario padrao que sera criado dentro do Debian (Sem espacos, letras minusculas)
$LinuxUsername = "devuser"
$LinuxPassword = "123" # Senha inicial para comandos sudo (Altere conforme preferir)

# 3. URL do instalador do Miniforge (Inclui Conda e Mamba para resolucao rapida)
$CondaInstallerUrl = "https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-x86_64.sh"

# 4. Diretorio de instalacao do Miniforge dentro do Linux
$CondaInstallDir = "/home/$LinuxUsername/miniforge3"

# 5. DEFINICAO DOS AMBIENTES CONDA E SEUS PACOTES (Nomes e versoes validados no Conda-Forge/Bioconda)
$CondaEnvironments = [ordered]@{
    "busco" = @(
        "busco"
    )
    "fastp" = @(
        "fastp"
    )
    "mob_suite" = @(
        "mob_suite=3.1.9"
    )
    "montagem" = @(
        "spades>=4.0.0",
        "seqtk=1.5"
    )
    "ncbi_datasets" = @(
        "ncbi-datasets-cli",
        "unzip"
    )
    "quast" = @(
        "python=3.11",
        "quast=5.3.0"
    )
    "reads" = @(
        "gdown",
        "libarchive"
    )
    "prokka" = @(
        "prokka"
    )
    "rgi" = @(
        "rgi"
    )
    "roary" = @(
        "roary"
    )
    "mlst" = @(
        "mlst"
    )
    "fasttree" = @(
        "fasttree"
    )
}

# 6. CONFIGURACAO DO DOWNLOAD E INDEXACAO AUTOMATICA DE BANCOS DE DADOS
$DownloadDatabases  = $true                            # Mude para $false se quiser pular todos os bancos
$DatabasesBaseDir   = "/home/$LinuxUsername/databases" # Pasta no Linux onde os bancos serao salvos

$SetupRgiDb         = $true   # Baixa e carrega o banco de dados CARD mais recente para o RGI
$SetupMobSuiteDb    = $true   # Baixa e inicializa os bancos de plasmideos do MOB-suite (mob_init)
$SetupProkkaDb      = $true   # Indexa os bancos de dados internos do Prokka (prokka --setupdb)
$SetupBuscoDb       = $true   # Baixa a linhagem base para o BUSCO
$BuscoLineage       = "bacteria_odb10" # Linhagem padrao do BUSCO a ser baixada

# ==============================================================================
# VERIFICACAO DE PRIVILEGIOS DE ADMINISTRADOR
# ==============================================================================
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "[ERRO] Por favor, execute este script como Administrador!" -ForegroundColor Red
    Exit 1
}

# ==============================================================================
# ETAPA 1: GARANTIR RECURSOS DO WINDOWS 10/11 E INSTALAR O DEBIAN NO WSL
# ==============================================================================
Write-Host "==> Verificando suporte ao WSL no Windows 10/11..." -ForegroundColor Cyan

# Garante que os recursos base do Windows 10/11 estao habilitados
$wslFeature = Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux -ErrorAction SilentlyContinue
$vmFeature  = Get-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform -ErrorAction SilentlyContinue

$needsReboot = $false
if ($wslFeature -and $wslFeature.State -ne "Enabled") {
    Write-Host "==> Habilitando Subsistema do Windows para Linux (DISM)..." -ForegroundColor Yellow
    dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart | Out-Null
    $needsReboot = $true
}
if ($vmFeature -and $vmFeature.State -ne "Enabled") {
    Write-Host "==> Habilitando Plataforma de Maquina Virtual para WSL 2 (DISM)..." -ForegroundColor Yellow
    dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart | Out-Null
    $needsReboot = $true
}

if ($needsReboot) {
    Write-Host "`n[ACAO NECESSARIA] Recursos de virtualizacao do Windows foram ativados pela primeira vez." -ForegroundColor Yellow
    Write-Host "Por favor, REINICIE o computador agora e execute este script novamente para continuar." -ForegroundColor Yellow
    Exit 0
}

# Garante que o kernel do WSL esteja atualizado e definido para WSL 2
wsl --update 2>$null
wsl --set-default-version 2 2>$null

Write-Host "==> Verificando status da distribuicao $DistroName..." -ForegroundColor Cyan
$wslList = wsl --list --quiet 2>$null
$distroInstalled = $false

if ($LASTEXITCODE -eq 0 -and $wslList) {
    $cleanList = $wslList -replace "`0", ""
    if ($cleanList -match "(?m)^$DistroName\r?$") {
        $distroInstalled = $true
    }
}

if (-not $distroInstalled) {
    Write-Host "==> Baixando e instalando $DistroName..." -ForegroundColor Yellow
    wsl --install -d $DistroName --no-launch
    
    Write-Host "==> Inicializando sistema de arquivos do $DistroName pela primeira vez..." -ForegroundColor Yellow
    # Quando instalado com --no-launch, o appx do Debian precisa ser acionado para registrar a distro no WSL
    $debianExe = Get-Command "debian.exe" -ErrorAction SilentlyContinue
    if ($debianExe) {
        & $debianExe.Source install --root
    } else {
        # Fallback caso o alias do Windows App ainda nao esteja no PATH da sessao atual
        $appxPkg = Get-AppxPackage -Name "*Debian*" | Select-Object -First 1
        if ($appxPkg -and (Test-Path (Join-Path $appxPkg.InstallLocation "debian.exe"))) {
            & (Join-Path $appxPkg.InstallLocation "debian.exe") install --root
        }
    }
    Start-Sleep -Seconds 3
} else {
    Write-Host "==> $DistroName ja esta instalado e registrado no WSL." -ForegroundColor Green
}

# Testa se a distro responde antes de prosseguir
wsl -d $DistroName -u root echo "WSL_OK" >$null 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERRO] A distribuicao $DistroName foi instalada, mas o Windows requer uma reinicializacao para carregar o WSL." -ForegroundColor Red
    Write-Host "Reinicie o computador e execute este script novamente." -ForegroundColor Yellow
    Exit 1
}

# ==============================================================================
# ETAPA 2: PREPARAR COMANDOS DE CRIACAO DOS AMBIENTES E BANCOS DE DADOS
# ==============================================================================
Write-Host "==> Preparando configuracao do Git, ambientes Conda/Bioconda e bancos de dados..." -ForegroundColor Cyan

$EnvCreationCommands = ""
foreach ($envName in $CondaEnvironments.Keys) {
    $quotedPkgs = $CondaEnvironments[$envName] | ForEach-Object { "'$_'" }
    $pkgList = ($quotedPkgs -join " ").Trim()
    
    if ($pkgList) {
        $EnvCreationCommands += @"

echo "------------------------------------------------------------"
echo ">>> Processando ambiente: '$envName' (Pacotes: $pkgList)"
echo "------------------------------------------------------------"
if ! conda info --envs | awk '{print `$1}' | grep -qx "$envName"; then
    echo "Criando ambiente '$envName'..."
    `$SOLVER_CMD create -n "$envName" --override-channels -c conda-forge -c bioconda $pkgList -y
else
    echo "Ambiente '$envName' ja existe. Garantindo instalacao/atualizacao dos pacotes..."
    `$SOLVER_CMD install -n "$envName" --override-channels -c conda-forge -c bioconda $pkgList -y
fi
"@
    }
}

# Converte flags booleanas do PowerShell para strings "true"/"false" do Bash
$DoDbStr      = if ($DownloadDatabases) { "true" } else { "false" }
$DoRgiStr     = if ($SetupRgiDb)        { "true" } else { "false" }
$DoMobStr     = if ($SetupMobSuiteDb)   { "true" } else { "false" }
$DoProkkaStr  = if ($SetupProkkaDb)     { "true" } else { "false" }
$DoBuscoStr   = if ($SetupBuscoDb)      { "true" } else { "false" }

# Template do script Bash principal
$BashProvisionScript = @'
#!/bin/bash
set -e

LINUX_USER="__LINUX_USER__"
LINUX_PASS="__LINUX_PASS__"
CONDA_URL="__CONDA_URL__"
CONDA_DIR="__CONDA_DIR__"

echo "---> [Linux] Configurando usuario padrao ($LINUX_USER)..."
if ! id "$LINUX_USER" &>/dev/null; then
    useradd -m -s /bin/bash "$LINUX_USER"
    echo "${LINUX_USER}:${LINUX_PASS}" | chpasswd
    usermod -aG sudo "$LINUX_USER"
    echo "$LINUX_USER ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/$LINUX_USER"
    chmod 0440 "/etc/sudoers.d/$LINUX_USER"
fi

# Garante que o usuario padrao esteja definido no /etc/wsl.conf
if ! grep -q "default=$LINUX_USER" /etc/wsl.conf 2>/dev/null; then
    printf "[user]\ndefault=%s\n" "$LINUX_USER" > /etc/wsl.conf
fi

echo "---> [Linux] Atualizando repositorios e pacotes do Debian..."
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get upgrade -y

echo "---> [Linux] Instalando Git, Python do sistema e dependencias essenciais..."
apt-get install -y git git-lfs python3 python3-pip python3-venv curl wget build-essential bzip2 tar unzip xz-utils ca-certificates procps

echo "---> [Linux] Verificando instalacao do Git: $(git --version)"

echo "---> [Linux] Configurando o Miniforge, Git, ambientes e bancos para o usuario $LINUX_USER..."

USER_SCRIPT="/tmp/setup_conda_user.sh"
cat << 'EOF_USER' > "$USER_SCRIPT"
#!/bin/bash
set -e

LINUX_USER="__LINUX_USER__"
CONDA_URL="__CONDA_URL__"
CONDA_DIR="__CONDA_DIR__"
DB_BASE_DIR="__DB_BASE_DIR__"
DO_DB="__DO_DB__"
DO_RGI="__DO_RGI__"
DO_MOB="__DO_MOB__"
DO_PROKKA="__DO_PROKKA__"
DO_BUSCO="__DO_BUSCO__"
BUSCO_LINEAGE="__BUSCO_LINEAGE__"

echo "Configurando parametros globais do Git para uso de git pull sem conflitos..."
git lfs install --skip-repo &>/dev/null || true
git config --global core.autocrlf input
git config --global pull.rebase false
git config --global http.postBuffer 524288000

if [ ! -d "$CONDA_DIR" ]; then
    echo "Baixando instalador do Miniforge..."
    wget -q --show-progress "$CONDA_URL" -O /tmp/miniforge_installer.sh
    
    echo "Executando instalador do Miniforge em modo silencioso..."
    bash /tmp/miniforge_installer.sh -b -p "$CONDA_DIR"
    rm -f /tmp/miniforge_installer.sh
    
    echo "Inicializando Conda e Mamba no terminal bash..."
    "$CONDA_DIR/bin/conda" init bash
else
    echo "Miniforge ja esta instalado em $CONDA_DIR."
fi

# Carrega o Conda e o Mamba na sessao atual
source "$CONDA_DIR/etc/profile.d/conda.sh"
if [ -f "$CONDA_DIR/etc/profile.d/mamba.sh" ]; then
    source "$CONDA_DIR/etc/profile.d/mamba.sh"
fi

echo "Configurando arquivo ~/.condarc com canais conda-forge e bioconda..."
cat << 'EOF_CONDARC' > "$HOME/.condarc"
channels:
  - conda-forge
  - bioconda
channel_priority: flexible
EOF_CONDARC

echo "Atualizando o gerenciador Conda/Mamba na base..."
conda update -n base -c conda-forge conda mamba -y

if command -v mamba &>/dev/null; then
    SOLVER_CMD="mamba"
else
    SOLVER_CMD="conda"
fi

# Remove ambientes antigos do bakta ou amrfinder caso existam de execucoes anteriores
for OLD_ENV in bakta bakta_env amrfinder amr_env; do
    if conda info --envs | awk '{print $1}' | grep -qx "$OLD_ENV"; then
        echo "Removendo ambiente descontinuado '$OLD_ENV'..."
        conda env remove -n "$OLD_ENV" -y
    fi
done

# Executa a criacao de cada ambiente separado
__ENV_CREATION_COMMANDS__

# ==============================================================================
# ETAPA DE DOWNLOAD, INDEXACAO E CONFIGURACAO DOS BANCOS DE DADOS
# ==============================================================================
if [ "$DO_DB" = "true" ]; then
    echo "============================================================"
    echo " INICIANDO DOWNLOAD E CONFIGURACAO DOS BANCOS DE DADOS "
    echo "============================================================"
    mkdir -p "$DB_BASE_DIR"

    # 1. Banco de dados CARD para o RGI (ambiente: rgi)
    if [ "$DO_RGI" = "true" ] && conda info --envs | awk '{print $1}' | grep -qx "rgi"; then
        echo "------------------------------------------------------------"
        echo ">>> [1/5] Baixando e carregando banco de dados CARD para o RGI (ambiente: rgi)..."
        echo "------------------------------------------------------------"
        conda activate rgi
        RGI_DB_DIR="$DB_BASE_DIR/card_rgi"
        mkdir -p "$RGI_DB_DIR"
        cd "$RGI_DB_DIR"

        if [ ! -f "$RGI_DB_DIR/card.json" ]; then
            echo "Baixando arquivo latest/data do CARD..."
            wget -q --show-progress -O card_data.tar.bz2 https://card.mcmaster.ca/latest/data
            tar -xjf card_data.tar.bz2
            rm -f card_data.tar.bz2
        else
            echo "Arquivo card.json ja existe em $RGI_DB_DIR."
        fi

        echo "Carregando card.json no RGI..."
        rgi load --card_json "$RGI_DB_DIR/card.json" --local
        rgi load --card_json "$RGI_DB_DIR/card.json" || true
        cd "$HOME"
        conda deactivate
    fi

    # 2. Banco de dados de Plasmideos do MOB-suite (ambiente: mob_suite)
    if [ "$DO_MOB" = "true" ] && conda info --envs | awk '{print $1}' | grep -qx "mob_suite"; then
        echo "------------------------------------------------------------"
        echo ">>> [2/5] Inicializando banco de dados do MOB-suite (ambiente: mob_suite)..."
        echo "------------------------------------------------------------"
        conda activate mob_suite
        MOB_DB_DIR="$DB_BASE_DIR/mob_suite_db"
        
        if [ ! -d "$MOB_DB_DIR" ] || [ -z "$(ls -A "$MOB_DB_DIR" 2>/dev/null)" ]; then
            mkdir -p "$MOB_DB_DIR"
            echo "Executando mob_init para baixar bancos de referencia do MOB-suite..."
            mob_init -d "$MOB_DB_DIR" || mob_init
        else
            echo "Banco do MOB-suite ja inicializado em $MOB_DB_DIR."
        fi
        conda env config vars set MOB_DB_DIR="$MOB_DB_DIR" -n mob_suite
        conda deactivate
    fi

    # 3. Indexacao dos bancos internos do Prokka (ambiente: prokka)
    if [ "$DO_PROKKA" = "true" ] && conda info --envs | awk '{print $1}' | grep -qx "prokka"; then
        echo "------------------------------------------------------------"
        echo ">>> [3/5] Indexando bancos de dados internos do Prokka (ambiente: prokka)..."
        echo "------------------------------------------------------------"
        conda activate prokka
        prokka --setupdb
        conda deactivate
    fi

    # 4. Download de linhagem padrao do BUSCO (ambiente: busco)
    if [ "$DO_BUSCO" = "true" ] && conda info --envs | awk '{print $1}' | grep -qx "busco"; then
        echo "------------------------------------------------------------"
        echo ">>> [4/5] Baixando banco de linhagem ($BUSCO_LINEAGE) do BUSCO (ambiente: busco)..."
        echo "------------------------------------------------------------"
        conda activate busco
        BUSCO_DB_DIR="$DB_BASE_DIR/busco_downloads"
        mkdir -p "$BUSCO_DB_DIR"
        
        if [ ! -d "$BUSCO_DB_DIR/lineages/$BUSCO_LINEAGE" ]; then
            cd "$DB_BASE_DIR"
            busco --download "$BUSCO_LINEAGE" --download_path "$BUSCO_DB_DIR" || true
            cd "$HOME"
        else
            echo "Linhagem $BUSCO_LINEAGE ja existe em $BUSCO_DB_DIR."
        fi
        conda env config vars set BUSCO_DOWNLOADS="$BUSCO_DB_DIR" -n busco
        conda deactivate
    fi

    # 5. Verificacao dos bancos PubMLST do MLST (ambiente: mlst)
    if conda info --envs | awk '{print $1}' | grep -qx "mlst"; then
        echo "------------------------------------------------------------"
        echo ">>> [5/5] Verificando esquemas e bancos de dados do MLST (ambiente: mlst)..."
        echo "------------------------------------------------------------"
        conda activate mlst
        mlst --check
        conda deactivate
    fi
fi

echo "Limpando pacotes baixados em cache do Conda para economizar espaco em disco..."
conda clean --all -y
EOF_USER

chown "$LINUX_USER:$LINUX_USER" "$USER_SCRIPT"
chmod +x "$USER_SCRIPT"

# Executa o script diretamente com o usuario padrao
su - "$LINUX_USER" -c "bash $USER_SCRIPT"
rm -f "$USER_SCRIPT"

echo "---> [Linux] Limpando cache de pacotes do apt..."
apt-get autoremove -y
apt-get clean

echo "============================================================"
echo " GIT, AMBIENTES E BANCOS DE BIOINFORMATICA CONFIGURADOS! "
echo "============================================================"
'@

# Injeta os valores configurados no PowerShell diretamente no script Bash
$BashProvisionScript = $BashProvisionScript.Replace("__LINUX_USER__", $LinuxUsername)
$BashProvisionScript = $BashProvisionScript.Replace("__LINUX_PASS__", $LinuxPassword)
$BashProvisionScript = $BashProvisionScript.Replace("__CONDA_URL__", $CondaInstallerUrl)
$BashProvisionScript = $BashProvisionScript.Replace("__CONDA_DIR__", $CondaInstallDir)
$BashProvisionScript = $BashProvisionScript.Replace("__ENV_CREATION_COMMANDS__", $EnvCreationCommands)
$BashProvisionScript = $BashProvisionScript.Replace("__DB_BASE_DIR__", $DatabasesBaseDir)
$BashProvisionScript = $BashProvisionScript.Replace("__DO_DB__", $DoDbStr)
$BashProvisionScript = $BashProvisionScript.Replace("__DO_RGI__", $DoRgiStr)
$BashProvisionScript = $BashProvisionScript.Replace("__DO_MOB__", $DoMobStr)
$BashProvisionScript = $BashProvisionScript.Replace("__DO_PROKKA__", $DoProkkaStr)
$BashProvisionScript = $BashProvisionScript.Replace("__DO_BUSCO__", $DoBuscoStr)
$BashProvisionScript = $BashProvisionScript.Replace("__BUSCO_LINEAGE__", $BuscoLineage)

# Converte quebras de linha do Windows (CRLF) para Linux (LF)
$BashProvisionScript = $BashProvisionScript -replace "`r`n", "`n"

Write-Host "==> Inicializando o $DistroName e executando a configuracao..." -ForegroundColor Cyan

# Salva o script temporariamente em UTF-8 sem BOM
$TempScriptPath = Join-Path $env:TEMP "wsl_provision.sh"
[System.IO.File]::WriteAllText($TempScriptPath, $BashProvisionScript, (New-Object System.Text.UTF8Encoding($false)))

# Converte o caminho do Windows para caminho montado no WSL (/mnt/c/...)
$WslTempPath = (wsl -d $DistroName -u root wslpath -u ($TempScriptPath -replace '\\', '/')).Trim()

# Executa o script dentro do Debian
wsl -d $DistroName -u root bash "$WslTempPath"

# Remove o arquivo temporario no Windows
Remove-Item $TempScriptPath -Force -ErrorAction SilentlyContinue

# Reinicia a instancia do WSL para aplicar o usuario padrao configurado no /etc/wsl.conf
wsl --terminate $DistroName

Write-Host "`n[CONCLUIDO] Git, ambientes e bancos de dados configurados com sucesso!" -ForegroundColor Green
Write-Host "Para acessar seu Linux, digite: wsl -d $DistroName" -ForegroundColor Yellow
Write-Host "Bancos de dados armazenados em: $DatabasesBaseDir" -ForegroundColor Cyan
Write-Host "Ambientes disponiveis para ativar com 'conda activate <nome>':" -ForegroundColor Cyan
foreach ($envName in $CondaEnvironments.Keys) {
    Write-Host "  - conda activate $envName  ($($CondaEnvironments[$envName] -join ', '))" -ForegroundColor White
}