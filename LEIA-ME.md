# MeuOS: seu sistema leve com cara de Mac

Feito para o Dell velho (i3, 8 GB de RAM, SSD de 224 GB).
A base é o Debian 13 mínimo. Por cima dele, este projeto instala e configura tudo:

- **Barra superior** com o seu logo, a janela ativa, o Wi-Fi, o volume, a bateria e o relógio.
- **Dock embaixo** (Plank) com efeito de zoom.
- **Busca de apps estilo Spotlight**: `Ctrl + Espaço`.
- **Tema WhiteSur** (janelas, ícones e cursor no estilo macOS) e botões de janela à esquerda.
- **Otimizações**: memória comprimida (zram), bateria (TLP), vídeo pela GPU, boot de 1 segundo e TRIM do SSD.
- **Apps**: Firefox, LibreOffice, mpv (vídeos), visualizador de imagens, calculadora e a loja Flathub (Spotify, Discord, VS Code...).

Para mudar o nome do sistema, o tema claro/escuro ou o atalho, edite o **`config.sh`**.

---

## Passo 0: teste antes no notebook novo (recomendado)

1. Instale o **VirtualBox** no notebook novo.
2. Crie uma VM Debian 64-bit com 2 GB de RAM e 20 GB de disco.
3. Siga os passos 2 e 3 abaixo dentro da VM.

Se algo der errado, você ajusta os arquivos e testa de novo sem mexer no notebook velho.

## Passo 1: pendrive de instalação (no notebook novo)

1. Baixe a ISO **Debian 13 netinst amd64** em <https://www.debian.org/download>.
2. Grave num pendrive com o **Rufus** (Windows) ou o **Ventoy**.
3. Copie esta pasta `meuos` para **outro pendrive**, ou suba-a para o GitHub e depois use `git clone`.

> ⚠️ Faça backup dos arquivos do notebook velho antes. A instalação apaga o disco.

## Passo 2: instalar o Debian mínimo (no notebook velho)

1. Ligue o notebook com o pendrive e aperte **F12** para abrir o menu de boot da Dell.
2. Escolha **Graphical install** e configure:
   - Idioma: Português do Brasil.
   - Teclado: ABNT2.
   - Conecte no Wi-Fi.
3. Senha de root: **deixe em branco**. Assim o seu usuário ganha o `sudo` automaticamente.
4. Particionamento: "Guiado - usar o disco inteiro", com tudo em uma partição.
5. **Na tela "Seleção de software", desmarque TUDO**, incluindo "Ambiente de desktop Debian" e "GNOME". Deixe marcado apenas **"utilitários de sistema padrão"**.
6. Termine a instalação e reinicie. Vai aparecer uma tela preta pedindo login, e é isso mesmo.

## Passo 3: transformar no seu sistema

Faça login com o seu usuário e rode:

```bash
# se a pasta estiver num pendrive:
sudo mount /dev/sdb1 /mnt && cp -r /mnt/meuos ~ && sudo umount /mnt
# (ou, se estiver no GitHub:  sudo apt install -y git && git clone SEU_LINK ~/meuos)

cd ~/meuos
sudo ./instalar.sh
sudo reboot
```

Demora de 15 a 30 minutos, dependendo da internet. No primeiro login o visual é aplicado sozinho em poucos segundos.

## Se algo der errado

- O log completo fica em `/var/log/instalar-sistema.log`.
- Pode rodar `sudo ./instalar.sh` de novo sem problema.
- Se o Wi-Fi não funcionar depois do Debian instalado, ligue um cabo de rede ou use o celular via USB (ancoragem).

## Apps do Windows

- **Office**: use o LibreOffice (já vem instalado) ou o Office pela web, no Firefox.
- **Programas `.exe`**: instale o *Bottles* pelo Flathub. Ele roda muitos programas de Windows.
- **Jogos**: instale a Steam com Proton.
