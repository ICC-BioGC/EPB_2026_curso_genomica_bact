# 0) Pacotes do sistema (wget e bsdtar)
sudo apt update && sudo apt install -y wget libarchive-tools

# 1) Miniforge (traz conda + mamba, já com conda-forge)
cd ~
wget -q https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-x86_64.sh
bash Miniforge3-Linux-x86_64.sh -b -p "$HOME/miniforge3"
rm Miniforge3-Linux-x86_64.sh
"$HOME/miniforge3/bin/conda" init bash
source ~/.bashrc

# 2) Canais
conda config --add channels bioconda
conda config --add channels conda-forge
conda config --set channel_priority strict

# 3) Ambientes
mamba create -y -n fastp     -c conda-forge -c bioconda fastp
mamba create -y -n montagem  -c conda-forge -c bioconda "spades>=4.0.0" "seqtk=1.5"
mamba create -y -n quast     -c conda-forge -c bioconda "python=3.11" "quast=5.3.0"
mamba create -y -n busco     -c conda-forge -c bioconda busco
mamba create -y -n mob_suite -c conda-forge -c bioconda "mob_suite=3.1.9"

# 4) Conferir
conda env list
bsdtar --version
