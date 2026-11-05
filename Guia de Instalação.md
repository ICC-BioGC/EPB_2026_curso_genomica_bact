## **Guia para Instalação do WSL Debian via script**

---

### **Baixando o Script**

1. Entre no Google Drive [clicando aqui](https://drive.google.com/drive/folders/1QmEnn0U5iFkLSvpfMnQvpYXa_6PBbtQ-?usp=drive_link)  
2. Baixe o arquivo `setup-wsl-debian-conda.rar`  
3. Mova o arquivo `setup-wsl-debian-conda.rar` para sua área de trabalho  
4. Extraia o arquivo obtendo `setup-wsl-debian-conda.ps1`

### **Executando o Powershell**

1. Abra o menu iniciar do Windows e busque por **Powershell**  
2. Abra o **Powershell** como administrador (deve aparecer na barra a direita, ou use o botão direito do mouse)  
3. Na linha de comando do **Powershell** copie e cole os comandos um por linha dando enter:

`cd ~/Desktop`

`Set-ExecutionPolicy Bypass -Scope Process -Force`

`./setup-wsl-debian-conda.ps1`

4. Depois que o script terminar de rodar rode os comandos um por linha dando enter:

`wsl --list --verbose`

`wsl -d Debian`

`cd  ~`

`mkdir aula`

5. Pronto, agora seu WSL está pronto para o uso\!

### **Preparando os Datasets do caso clínico**

1. Entre no Google Drive \[clicando aqui\]  
2. Baixe o arquivo `paired_end_data.rar`  
3. Extraia o arquivo `paired_end_data.rar`  
4. Copie a pasta extraída `paired_end_data`  
5. Na barra lateral esquerda do explorer do Windows busque por **Linux**  
6. Depois clique na pasta **Debian**  
7. Siga esses diretórios:

`home/devuser/aula`

8. Cole a pasta `paired_end_data`  
9. Depois rode os comandos um por linha dando enter:

`cd aula`

`find . -name "*Zone.Identifier" -type f -delete`

10. Você está pronto para começar\!

&nbsp;

---

## **Guia para desinstalar o Debian e remover os dados após as aulas**

### **Executando o Powershell**

*ATENÇÃO: Esses comandos vão remover completamente o Debian e todos os dados dentro das pastas dele\!*

1. Abra o menu iniciar do Windows e busque por **Powershell**  
2. Abra o **Powershell** como administrador (deve aparecer na barra a direita, ou use o botão direito do mouse)  
3. Na linha de comando do **Powershell** copie e cole os comandos um por linha dando enter:

`wsl --terminate Debian`

`wsl --unregister Debian`

&nbsp;

---

## **Guia de parâmetros para instalação manual**

### **Manual do WSL**

1. Acesse o site oficial do WSL [Instalar o WSL \| Microsoft Learn](https://learn.microsoft.com/pt-br/windows/wsl/install)&nbsp;  
2. Na hora de executar a instalação utilize a Distro

`wsl.exe --install -d Debian`

3. Após a instalação inicie o Debian:

`wsl -d Debian`

4. Atualize o Debian:

`apt-get update -y`

`apt-get upgrade -y`

*ATENÇÃO:* Certos pacotes como prokka, rgi e busco exigem baixar e configurar o banco de dados. Caso não queira fazer isso manualmente, tente finalizar o Debian com `wsl --terminate Debian` e executar o script. O script irá continuar a partir da sua instalação do WSL.

5. Instale o Python

`apt-get install -y python3 python3-pip python3-venv curl wget git build-essential bzip2 tar ca-certificates procps`

6. Instale o gerenciador de pacotes conda, adicione o conda-forge como repositório e instale os seguintes pacotes em seus respectivos ambientes:

´"busco" \= @(

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;"busco"

&nbsp;&nbsp;&nbsp;&nbsp;)

&nbsp;&nbsp;&nbsp;&nbsp;"fastp" \= @(

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;"fastp"

&nbsp;&nbsp;&nbsp;&nbsp;)

&nbsp;&nbsp;&nbsp;&nbsp;"mob\_suite" \= @(

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;"mob\_suite=3.1.9"

&nbsp;&nbsp;&nbsp;&nbsp;)

&nbsp;&nbsp;&nbsp;&nbsp;"montagem" \= @(

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;"spades\>=4.0.0",

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;"seqtk=1.5"

&nbsp;&nbsp;&nbsp;&nbsp;)

&nbsp;&nbsp;&nbsp;&nbsp;"ncbi\_datasets" \= @(

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;"ncbi-datasets-cli",

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;"unzip"

&nbsp;&nbsp;&nbsp;&nbsp;)

&nbsp;&nbsp;&nbsp;&nbsp;"quast" \= @(

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;"python=3.11",

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;"quast=5.3.0"

&nbsp;&nbsp;&nbsp;&nbsp;)

&nbsp;&nbsp;&nbsp;&nbsp;"reads" \= @(

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;"gdown",

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;"libarchive"

&nbsp;&nbsp;&nbsp;&nbsp;)

&nbsp;&nbsp;&nbsp;&nbsp;"prokka" \= @(

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;"prokka"

&nbsp;&nbsp;&nbsp;&nbsp;)

&nbsp;&nbsp;&nbsp;&nbsp;"rgi" \= @(

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;"rgi"

&nbsp;&nbsp;&nbsp;&nbsp;)

&nbsp;&nbsp;&nbsp;&nbsp;"roary" \= @(

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;"roary"

&nbsp;&nbsp;&nbsp;&nbsp;)

&nbsp;&nbsp;&nbsp;&nbsp;"mlst" \= @(

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;"mlst"

&nbsp;&nbsp;&nbsp;&nbsp;)

&nbsp;&nbsp;&nbsp;&nbsp;"fasttree" \= @(

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;"fasttree"

&nbsp;&nbsp;&nbsp;&nbsp;)

&nbsp;

&nbsp;

&nbsp;