# UbuntoARM

Ubuntu 26.10 arm64 no **Lenovo IdeaPad 5 2-in-1 14Q8X9 (tipo 83GH)**, Snapdragon X Plus X1P42100
("Purwa"), Adreno X1-45. Parte da imagem oficial `Ubuntu 26.10 arm64+x1e` (kernel `linux-qcom-x1e 7.3.0-15`)
e corrige o que impede o boot e o uso diário nesse modelo. Instalado em dual boot com o Windows e em uso.

*English summary at the end.*

## O que funciona

| Componente | Estado |
|---|---|
| Boot, tela OLED, USB, SSD NVMe | ✅ |
| Wi-Fi 7 / Bluetooth (FastConnect 7800) | ✅ |
| Teclado e touchpad internos | ✅ |
| Tela touch e caneta Wacom | ✅ |
| Bateria / carregamento | ✅ |
| Som (alto-falantes, microfones) | ✅ |
| Câmera (USB `30c9:00de`) e leitor de digital (Elan `04f3:0c98`) | ✅ |
| Frequência da CPU (SCMI, até 3,24 GHz) e temperaturas | ✅ |
| GPU Adreno X1-45 (firmware SQE/GMU, Mesa) | ✅ |
| Brilho da tela | ✅ com a extensão `oled-brilho` (ver abaixo) |
| Modo tablet e rotação | ✅ **manual**, botão nas configurações rápidas (extensão `tablet`) |
| Detecção automática de dobradiça/orientação | ❌ os sensores ficam no ADSP; ver "Sensores" |
| Suspensão | não testada a fundo |

## O que foi corrigido

1. **Reset ao carregar a interconexão (`qnoc_x1e80100`).** Ao registrar cada barramento (NoC), o núcleo de
   interconexão vota banda máxima (`INT_MAX`) em todos os nós até o `sync_state`; no 83GH isso reinicia a
   máquina. [`kernel/qnoc-83gh`](kernel/qnoc-83gh/qnoc-83gh.c) é o mesmo módulo com banda inicial 0.
2. **Device tree.** O DTB do 2-in-1 da árvore do Jens Glathe ainda reinicia o 83GH (~15 s, ao subir o PCIe do
   Wi-Fi). O DTB do **IdeaPad Slim 5x** do Ubuntu sobe; o usado é ele mais os overlays de [`dt/`](dt):
   teclado/touchpad (`i2c2`), Wacom (`i2c8`), firmware do 83GH nos DSPs/GPU/vídeo e a câmera (regulador no
   GPIO 44, que o Slim 5x reserva, e os repetidores eUSB ligados como no 2-in-1). Vai embutido no `vmlinuz`
   como `.dtbauto`.
3. **Áudio.** A regra do UCM em `alsa-ucm-conf` procura `Ideapad.*5.*`, mas o DMI diz `IdeaPad`: sem som.
   A correção (`[Ii]dea[Pp]ad`) é aplicada e protegida contra atualizações do pacote.
4. **Brilho.** O OLED Samsung ATNA40CT01 (`SDC 0x4187`) anuncia brilho de 16 bits pelo AUX do eDP, mas
   **satura em 2047** (o DT do Jens Glathe tem `max-brightness = <2047>`, que o kernel do Ubuntu ignora).
   O GNOME usava 655–65535 linearmente: só os primeiros ~2% do controle faziam efeito e não descia abaixo de
   32% da luz real. A extensão [`oled-brilho`](base-overlay/usr/share/gnome-shell/extensions/oled-brilho@ubuntoarm)
   grava pelo logind na faixa 40–2047 com curva gama e não deixa o esmaecimento por inatividade "prender" o
   brilho baixo.
5. **Kernel travado.** Qualquer kernel do apt sem estas correções reinicia o aparelho no boot. O serviço
   [`ubuntoarm-protege`](base-overlay/usr/local/sbin/ubuntoarm-protege) bloqueia pacotes de kernel no apt, fixa
   o GRUB no 7.3.0-15 corrigido e protege a correção do UCM.
6. **Modo tablet.** Extensão [`tablet`](base-overlay/usr/share/gnome-shell/extensions/tablet@ubuntoarm): desliga
   teclado e touchpad internos (atributo `inhibited`, liberado só para eles por
   [regra udev](base-overlay/etc/udev/rules.d/70-ubuntoarm-tablet.rules)), liga o teclado na tela, gira a tela
   interna e mostra um botão de teclado na barra. Faz o teclado na tela abrir também em apps Chromium/Electron
   (o Mutter só o pede num segundo `enable` do text-input-v3, que esses apps não mandam).
7. **Brave/Chromium.** Restos de desenho na tela com a rasterização por GPU no freedreno: usar
   `--disable-gpu-rasterization` (e `--enable-wayland-ime --wayland-text-input-version=3` para o teclado na tela).

O diário completo da investigação, rodada a rodada, está em [PLANO.md](PLANO.md).

## Firmware

O firmware dos DSPs, da GPU e do vídeo é proprietário (Qualcomm/Lenovo) e **assinado para o aparelho**, por
isso **não está neste repositório**. Cada um copia o do próprio Windows do notebook:

```bash
# Linux, com a partição do Windows montada (ex.: udisksctl mount -b /dev/nvme0n1p3 -o ro)
bash scripts/extract-firmware.sh /run/media/$USER/<id-da-partição>
```
```powershell
# ou no Windows, na raiz do projeto
.\scripts\extract-firmware.ps1
```

Os dois gravam em `firmware/windows-driverstore/` (ignorada pelo git).

## Como gerar o pendrive e instalar

Testado com: o próprio Windows do notebook, WSL2 com Ubuntu arm64 e um pendrive com a ISO
`Ubuntu 26.10 arm64+x1e` gravada (FAT32). **Secure Boot desligado** (o kernel é modificado).

```bash
# WSL, como root, na raiz do projeto, depois de extrair o firmware
mkdir -p /mnt/e && mount -t drvfs E: /mnt/e
bash scripts/prepare.sh /mnt/e          # copia kernel/initrd/camadas da ISO e os headers do kernel
bash scripts/build-all.sh               # DTB híbrido, módulo de interconexão, initrd e camada live
bash scripts/build-base-layer.sh        # camada que o instalador copia para o SSD (com as extensões)
```
```powershell
.\scripts\write-usb.ps1 -Drive E        # Windows: grava no pendrive e confere os hashes
```

No boot (F12), escolha **"Ubuntu - IdeaPad 5 2-in-1 (83GH)"**. Para instalar ao lado do Windows: deixe espaço
não alocado no SSD, desligue a Inicialização Rápida (`powercfg /h off`), escolha "instalar ao lado do Windows"
(**nunca** "apagar o disco") e não marque "baixar atualizações durante a instalação".

Se um kernel novo do apt chegar a ser instalado e o boot reiniciar, `scripts/ubuntoarm-reparo.sh`, rodado do
pendrive live, devolve o kernel corrigido e reativa a proteção.

## Sensores (dobradiça, orientação): não funcionam

Os dois acelerômetros e o sensor de ângulo da tampa ficam no ADSP (Qualcomm Sensor Core). Servindo a
configuração e o registro do Windows pelo `hexagonrpcd`, o ADSP reinicia a placa inteira **assim que calcula
o HMAC do registro de sensores** (para validar o `sns_secure_database.bin` ou criar um novo), sem deixar log.
Achados e ferramentas em [`scripts/debug/sensores`](scripts/debug/sensores); **não rode sem saber que vai dar
reset**. O modo tablet por isso é manual.

## Estrutura

- `scripts/` — pipeline de build e reparo; `scripts/debug/` — scripts usados na investigação.
- `kernel/qnoc-83gh/` — módulo de interconexão corrigido.
- `dt/` — overlays do 83GH.
- `base-overlay/` — o que vai para o sistema instalado (GRUB, proteção do kernel, extensões, regra udev).
- `live-overlay/` — serviço que grava o log de cada boot no pendrive.

## Licenças

- Código deste projeto: GPL-2.0-or-later ([LICENSE](LICENSE)).
- `kernel/qnoc-83gh/`: GPL-2.0 (derivado do Linux 7.3).
- `dt/`: BSD-3-Clause (derivados do DTS do Jens Glathe).
- `scripts/debug/sensores/hexagonrpcd-ubuntoarm.patch`: GPL-3.0, como o [hexagonrpc](https://github.com/linux-msm/hexagonrpc).
- O firmware não faz parte do projeto e continua sob a licença da Qualcomm/Lenovo.

## Créditos

- Jens Glathe — device trees do IdeaPad 5 2-in-1 / Slim 5x ([jglathe/linux_ms_dev_kit](https://github.com/jglathe/linux_ms_dev_kit)).
- Canonical — Ubuntu Concept, imagem arm64+x1e e kernel `linux-qcom-x1e`.
- Kernel Linux, linux-msm (hexagonrpc) e a comunidade aarch64-laptops.

---

## English summary

Ubuntu 26.10 arm64 on the **Lenovo IdeaPad 5 2-in-1 14Q8X9 (83GH)**, Snapdragon X Plus X1P42100, built
on top of the official `arm64+x1e` image (kernel `linux-qcom-x1e 7.3.0-15`). Installed and in daily use.

Findings that may help upstream:

- **Interconnect reset:** `qnoc_x1e80100` voting `INT_MAX` initial bandwidth on every NoC hard-resets the 83GH;
  starting at 0 bandwidth boots (`kernel/qnoc-83gh`).
- **DT:** the IdeaPad 5 2-in-1 DTB from jglathe's tree still resets ~15 s in (PCIe4/WCN7850 bring-up);
  Ubuntu's Slim 5x DTB plus the overlays in `dt/` works (camera needs GPIO 44 unreserved).
- **Audio:** `alsa-ucm-conf` matches `Ideapad.*5.*`, but DMI reports `IdeaPad`.
- **Backlight:** Samsung ATNA40CT01 (`SDC 0x4187`) advertises 16-bit DPCD brightness but saturates at 2047.
- **OSK:** Mutter only requests the on-screen keyboard on a second text-input-v3 `enable` while focused; Chromium
  and Electron send one, so the OSK never shows for them.
- **Sensors:** serving the Windows sensor registry through hexagonrpcd makes the board hard-reset as soon as the
  ADSP computes the registry HMAC.

Firmware is not included: extract it from your own Windows install with `scripts/extract-firmware.sh` or
`scripts/extract-firmware.ps1`.
