# UbuntoARM — Ubuntu 26.10 arm64 para o Lenovo IdeaPad 5 2-in-1 14Q8X9

## O notebook (levantado no Windows em 2026-11-15)

| Item | Detalhe |
|---|---|
| Modelo | Lenovo IdeaPad 5 2-in-1 14Q8X9, tipo **83GH**, BIOS Q1CN30WW |
| SoC | Snapdragon X Plus **X1P42100** ("Purwa"), 8 núcleos Oryon |
| GPU | Adreno X1-45 |
| RAM / disco | 16 GB / NVMe Samsung 512 GB |
| Wi-Fi / BT | Qualcomm FastConnect 7800 (WCN7850, PCI 17cb:1107) |
| Tela | Painel SDC4187, touch + caneta Wacom (WACF2200, I2C-HID) |
| Teclado/touchpad | I2C-HID (QTEC0001) |
| Câmera | USB UVC 30c9:00de |
| Digital | Elan USB 04f3:0c98 |
| Áudio | Qualcomm Aqstic (ADSP), cartão `X1E80100-LENOVO-Ideapad-5` |
| Outros | leitor microSD BayHub, sensor de presença, sensores de orientação/modo tablet (via ADSP) |

## Situação do suporte Linux

- **Device tree**: existe `x1p42100-lenovo-ideapad-5-2in1` no kernel do Jens Glathe
  (`github.com/jglathe/linux_ms_dev_kit`, branch `jg/ubuntu`). **Ainda não está no kernel oficial.**
  O Omarchy já empacotou (kernel 7.3, patches 2670–2673, commit `cbfc28f`, nov/2026).
- **Seleção do DTB no boot**: dtbloader já reconhece o 83GH; systemd-stub 262 também (via HWIDs).
- **Firmware**: precisa ser copiado do Windows (assinado para este aparelho). Encontrado no DriverStore:
  - `qcadsp8380.mbn`, `adsp_dtbs.elf`, `adspr.jsn`, `adsps.jsn`, `adspua.jsn`, `battmgr.jsn` (áudio, bateria, sensores)
  - `qccdsp8380.mbn`, `cdsp_dtbs.elf`, `cdspr.jsn` (DSP de computação)
  - `qcdxkmsucpurwa.mbn` (zap shader da GPU para Purwa), `qcvss8380.mbn`, `qcav1e8380.mbn`
- **Áudio**: falta o arquivo de topologia `X1E80100-LENOVO-Ideapad-5-tplg.bin` — sem ele, sem som.

## Expectativa realista por componente

| Componente | Expectativa |
|---|---|
| CPU, NVMe, USB-A/C, teclado, touchpad | Funciona com o DTB |
| Tela, brilho, GPU (Freedreno/Turnip) | Funciona com DTB + firmware da GPU |
| Wi-Fi / Bluetooth (ath12k) | Funciona; Wi-Fi pode não voltar após suspensão |
| Bateria / carregamento | Funciona com firmware do ADSP |
| Touch + caneta Wacom | Provável (I2C-HID padrão), precisa testar |
| Câmera | Provável (é USB UVC, não a câmera MIPI difícil) |
| Áudio | Precisa topologia + UCM — trabalho nosso |
| Digital Elan | Depende do libfprint suportar 04f3:0c98 — não verificado |
| Giro de tela / modo tablet | Difícil (sensores no ADSP) |
| NPU Hexagon | Fora do escopo |
| Suspensão | Instável no Snapdragon X em geral |

## Caminho proposto

1. **Ambiente de build**: WSL2 com Ubuntu arm64 neste próprio notebook (compila nativo, sem cross-compile).
2. **Firmware**: extrair do Windows para um pacote `.deb` (`ubuntoarm-firmware`).
3. **Kernel**: kernel do Ubuntu 26.10 + patches do device tree do 83GH (base: jglathe / Omarchy), empacotado em `.deb`.
4. **Boot**: DTB embutido via stubble/systemd-stub, sem precisar editar GRUB na mão.
5. **Áudio**: topologia + perfis UCM para o cartão IdeaPad-5.
6. **ISO**: remasterizar a ISO oficial do Ubuntu 26.10 arm64 com os pacotes acima.
7. **Teste**: pendrive live primeiro, sem tocar no Windows; instalação em dual boot só depois.

## Status (2026-11-15)

Pendrive SanDisk 32 GB com Ubuntu 26.10 daily `arm64+x1e` (kernel `linux-qcom-x1e 7.3.0-15`), modificado:

- **DTB do 83GH**: o kernel do Ubuntu já mapeava o 83GH (`.hwids`) para `lenovo,ideapad-5-2in1`, mas não trazia esse DTB.
  Compilado do kernel do Jens Glathe (commit `35e73a004cbe`, 7.3.0-jg-4) e embutido como seção `.dtbauto` no `vmlinuz`.
- **Firmware do Windows** em `qcom/x1p42100/LENOVO/83GH/` no initrd (segmento cpio no início) e na camada live.
- **Áudio**: topologia `X1E80100-LENOVO-Ideapad-5-tplg.bin.zst` (cópia da Romulus/T14s) e
  regex do UCM corrigida (`Ideapad` → `[Ii]dea[Pp]ad`, o DMI diz "IdeaPad").
- GRUB: entrada 83GH, entrada diagnóstico (sem splash) e entrada com kernel original.
- Originais em `work/usb/`. Reconstruir: `scripts/build-dtb.sh` e depois `scripts/build-live-83gh.sh` (root no WSL).
- `vmlinuz` sem assinatura (já era): **Secure Boot desligado**.
- Instalação no disco ainda não leva firmware/UCM/DTB (só o live tem).

### Teste 1 (2026-11-15): reset de hardware no initramfs
- Todas as entradas (DTB 83GH, DTB Slim 5x, kernel original, sem DSP/GPU/microSD) reiniciam ~10 s após o boot.
- Com `initcall_debug boot_delay`: reset logo após `qnoc_x1e80100` (módulo de interconexão) carregar e os
  drivers embutidos que esperavam por ele (SCM, SMMU, PCIe, GENI) tentarem de novo.
- Bisect: `scripts/build-bisect.sh` gera `vmlinuz.t1..t8`.
  - Rodada 1: sem `qnoc_x1e80100` → não reinicia (confirma). Sem PCIe / QUP / USB / vídeo+DSP (t1..t4), um por vez → reinicia.
  - Rodada 2: sem SMMU (t5), sem SCMI (t6), sem SCM (t7), t1..t4 juntos (t8) → todos reiniciam.
  - Rodada 3: t10 = t5..t8 juntos (só interconexão) e t9 = PDC `qcom,x1p42100-pdc` → ambos reiniciam.
  - Rodada 4: sem `llcc_qcom` e sem `icc_bwmon` → reiniciam. Vídeo do t10 lento: os provedores qnoc
    sobem em ordem (interconnect-0, -1, @1500000 cnoc-main, @1600000 cnoc-cfg OK) e o reset vem no
    próximo: **@1680000 system-noc** (BCMs SN0/SN2/SN3/SN4, voto inicial INT_MAX).
  - Rodada 5:
    - Correção: `kernel/qnoc-83gh` = qnoc-x1e80100.ko com probe copiado + `get_bw` → banda inicial 0
      (`zero_init=1`). `scripts/build-qnoc.sh` + `scripts/build-initrd-qnoc.sh` → `initrd.qnoc`.
      **Funcionou**: passa da interconexão e chega na tela do Ubuntu (plymouth); reinicia ~20 s depois.
    - Controle t11 (sem system-noc): reinicia no provedor seguinte → a causa é o voto INT_MAX em
      vários barramentos, não um barramento específico.
  - Rodada 6, todos com `initrd.qnoc`: blacklist de tudo (DSP/GPU/Wi-Fi/BT/bateria), só `qcom_q6v5_pas`,
    só `msm`, só Wi-Fi/BT → todos mostram a tela do Ubuntu e reiniciam depois.
  - Rodada 7: serviço `ubuntoarm-bootlog` (live-overlay/) grava dmesg + journal em
    `/cdrom/ubuntoarm-logs/` com sync a cada segundo. break=premount → não reinicia (tela preta).
    Boot normal e sem DSP/GPU/Wi-Fi → ambos param em `qcom-pcie 1c08000.pcie: iATU: unroll T...` (~15 s,
    já no systemd): reset ao subir o **PCIe 4 (Wi-Fi WCN7850)**. DT do PCIe4/WCN igual ao do Slim 5x;
    diferença: `operating-points-v2` nos PCIe (só na árvore do jglathe).
  - Rodada 8 (com initrd.qnoc): t12 sem PCIe 4 → reinicia; t13 sem OPP → reinicia;
    **DTB do Slim 5x do Ubuntu → chega no desktop** (tela, Wi-Fi, BT, USB, NVMe, câmera, digital Elan OK;
    sem teclado/touchpad/touch, DSPs offline → sem bateria/som, firmware procurado em 83HL).
  - Causa 2: o DTB do jglathe tem o compatible extra `lenovo,thinkpad-t14s` (para liberar variáveis EFI via
    QSEECOM/uefisecapp). Slim 5x do jglathe vs Ubuntu: única diferença é essa. `build-dtb.sh` agora remove.
  - Rodada 9: DTB do 2-in-1 sem o fallback T14s → **ainda reinicia** (~15 s, PCIe4 iATU). Log do Slim 5x mostra
    que o uefisecapp também sobe lá → T14s não era a causa. Diferença que sobra: no 2-in-1 os DSPs sobem com o
    firmware do Windows (CDSP: "timeout waiting for subsystem event response"); no Slim 5x não acham firmware (83HL).
  - Rodada 10: DTB híbrido = Slim 5x do Ubuntu + overlays em `dt/` (`scripts/build-hybrid.sh`):
    h1 teclado/touchpad no i2c2 → reinicia; h2 + Wacom no i2c8 → reinicia;
    **h3 + firmware 83GH nos DSPs/GPU/iris → funciona**: teclado, touchpad, bateria, som, Wi-Fi.
    Faltam: câmera (regulador VREG_CAM_5P0 GPIO 44 + usb_2_hsphy no eusb9_repeater), GPU
    (`qcom/gen71500_sqe.fw` ausente), cpufreq (scmi_cpufreq não carrega), temperaturas.
  - Rodada 11 (pendente): h4 = h3 + `dt/83gh-camera.dtso` (VREG_CAM_5P0; repetidores eUSB cruzados
    como no 2-in-1: usb_2→redriver@4b reset GPIO 7, usb_1_ss2→redriver@43 sem reset);
    `gen71500_sqe.fw`/`gen71500_gmu.bin` no initrd (o msm carrega no initrd e não tenta de novo);
    entrada de teste com `modules_load=scmi_perf_domain,scmi_cpufreq` (sem alias, nunca carregam sozinhos).
    Resultado: boota; **cpufreq OK** (max 3,24 GHz) → virou padrão via `/etc/modules-load.d/ubuntoarm.conf`;
    **GPU carrega SQE/GMU** ("Loaded GMU firmware v4.6.4"); leitor de digital passou a aparecer (usb_1_ss2);
    câmera não: `tlmm: error -EINVAL: pin-44` — o Slim 5x reserva GPIOs 44-47 (`gpio-reserved-ranges`).
    Câmera no Windows: ACPI USB4 (QCOM0D09) porta 1 = usb_2.
  - Rodada 12: overlay da câmera com `gpio-reserved-ranges = <34 2>, <72 2>` (igual ao 2-in-1) →
    **câmera e leitor de digital OK**. Diag: temperaturas em 30 zonas tsens; brilho `dp_aux_backlight`
    raw 0–65535 (scale unknown), sem erros de AUX.
  - Rodada 13 (pendente): zona `cpuss0-top-thermal` renomeada para `cpu-thermal` (o GNOME Resources só lê
    esse nome); `ubuntoarm-brilho.sh` mede a rampa de brilho.
  - SSD: C: encolhido de 475,9 para 325,9 GB (150 GB não alocados); hibernação/Inicialização Rápida desligadas.
  - Instalador: `scripts/build-base-layer.sh` aplica tudo na `minimal.squashfs` (que o instalador copia e o live
    usa por baixo): firmware 83GH + GPU, topologia/UCM, qnoc com banda 0, `/boot/vmlinuz` = h4, modules-load
    (cpufreq), `base-overlay/` (GRUB: params + cutmem; hook do initramfs com o firmware), kernel em hold.
    mksquashfs direto em /mnt/c ou com 8 processos falha por memória no WSL → gera no ext4, 4 processos, -mem 1G.
    Não testado ainda: instalação de fato, grub-install/variáveis EFI, initramfs gerado no alvo.
  - Instalação feita (partição 5, 150 GB). Primeiro boot OK no 7.3.0-15. **O instalador perdeu os holds** e
    o "Atualizações de Software" instalou o 7.3.0-31 (20:34), que virou padrão no GRUB → reset no boot.
    Diagnóstico lendo o ext4 direto do SSD pelo Windows: `scripts/read-ubuntu-disk.py` (admin, só leitura,
    pacote PyPI `ext4`, leitor alinhado a 4 KiB sobre `\\.\PhysicalDrive0`).
  - Proteção (`base-overlay/usr/local/sbin/ubuntoarm-protege` + serviço a cada boot): pin -1 para todo
    pacote de kernel, 7.3.0-15 em manual+hold, `GRUB_DEFAULT` fixo no 7.3.0-15, desvio (dpkg-divert) do UCM.
    `ubuntoarm-reparo.sh` remove os kernels ≠ 7.3.0-15 e os metapacotes, instala e roda a proteção.
  - Brave (snap e .deb): o "Segmentation fault" não se repetiu no sistema instalado. **Glitch de desenho resolvido**
    (restos de dígitos sobrepostos no speedtest): é a rasterização por GPU do Chromium no freedreno (Adreno X1-45);
    `--disable-gpu-rasterization` some com ele (teste A/B confirmado). Aplicado numa cópia do atalho em
    `~/.local/share/applications/brave-browser.desktop` (o Brave não lê arquivo de flags). Por usuário; não vai no
    instalador porque o Brave não faz parte dele. Outros navegadores Chromium devem precisar do mesmo.
  - Reparo confirmado (2026-11-15, sessão no Ubuntu): boota no 7.3.0-15 com a proteção ativa. Funcionam teclado,
    touchpad, touch e caneta Wacom, Wi-Fi, BT, som, bateria (80%, saúde 97%), cpufreq, câmera, digital e GPU.
  - **Brilho resolvido**: o OLED Samsung ATNA40CT01 (`SDC 0x4187`) anuncia brilho de 16 bits pelo AUX, mas
    **satura em 2047** (o DT do jglathe tem `max-brightness = <2047>`, que o kernel do Ubuntu ignora). O GNOME 51
    espalhava o controle linearmente em 655..65535 (só os primeiros ~2% faziam efeito) e o Mutter recusa < 655
    (= 32% da luz real). Correção: extensão `oled-brilho@ubuntoarm` (base-overlay/usr/share/gnome-shell/extensions),
    que grava pelo logind (`Session.SetBrightness`, sem root) na faixa 40..2047 com gama 2,2; ativa por padrão via
    `90_ubuntoarm.gschema.override`. Becos sem saída: FRC do eDP (`0x721` bit 2) não ajuda. `scripts/debug/dpcd-brilho.sh`
    lê os registradores. No sistema já instalado ela está em `~/.local/share/gnome-shell/extensions`.
    Esmaecimento por inatividade (gsd → `org.gnome.Shell.Brightness.SetDimming`) não voltava: o Shell adotava o
    valor esmaecido como escolha do usuário. Corrigido (a extensão ignora os valores que ela mesma gravou);
    testado com `SetDimming true/false`: 2047 → 182 → 2047, duas vezes.
  - Modo tablet / rotação: nenhum sensor exposto ao Linux (sem acelerômetro IIO, sem `SW_TABLET_MODE`; o HID do
    teclado ITE 048D:8987 não tem chave de dobradiça). Os sensores (2 acelerômetros, ângulo da tampa) ficam no ADSP.
    **Sensores do ADSP: beco sem saída por enquanto — cada tentativa dá reset de hardware.** Caminho testado
    (`scripts/debug/sensores/`, logs com fsync por passo): hexagonrpcd (Ubuntu 0.4.0 e upstream 0.5.0) servindo a
    config do DriverStore (`qcsensorsconfigcrd8380`, hw_platform=CRD), o registro pronto do Windows
    (`System32/drivers/DriverData/QUALCOMM/fastRPC/persist/sensors/registry/registry`) e as libs do ADSP
    (`qcsubsys_ext_adsp8380/ADSP` → `dsp/adsp/`). Achados: o `sns_reg_config` do Windows tem CRLF (o `\r` vai
    para o caminho — tirar); o ADSP pede `apps_std_fremove` (método 24, patch em `hexagonrpcd-ubuntoarm.patch`).
    **Causa do reset:** assim que o ADSP calcula um HMAC do registro (validar `sns_secure_database.bin` ou criar um
    novo), a placa reseta na hora, sem log. Segurar o ADSP 30 s antes disso não reseta; voto de banda no motor de
    criptografia (`ubuntoarm_ce_vote.c`) não muda nada. Provável chamada segura (TrustZone) da "HMAC API".
    Tudo desligado (`hexagonrpcd`/`qrtr-ns` disabled).
  - **Modo tablet manual**: extensão `tablet@ubuntoarm` (botão nas configurações rápidas): desliga teclado e touchpad
    internos pelo `inhibited` do kernel (regra udev `70-ubuntoarm-tablet.rules` libera só esses dois), liga o teclado
    na tela e tem menu de rotação (D-Bus do Mutter, só a tela interna, temporária). Religa tudo ao desativar/sair.
    Teclado na tela preso ao modo tablet (liga ao entrar, desliga ao sair e no login). Botão de teclado na barra
    superior no modo tablet (abre/fecha; não pega o foco, senão o GNOME fecha o teclado). Abertura automática em
    Chromium/Electron (Brave, app do Claude): o Mutter só pede o teclado num 2º `enable` do text-input-v3 com o
    campo já focado (GTK reenvia a cada toque, Chromium manda um só); no modo tablet a extensão envolve o
    `focus_in` do contexto IBus do Shell e abre o teclado em todo foco de campo. Testado e funcionando.
    Brave também com `--enable-wayland-ime --wayland-text-input-version=3` no atalho.

## Correções até agora
1. `kernel/qnoc-83gh`: interconexão com banda inicial 0 (reset ao votar INT_MAX em vários NoCs).
2. ~~DTB do 83GH sem `lenovo,thinkpad-t14s`~~ (não era a causa; mantido fora por segurança).
3. Em teste: DTB híbrido (Slim 5x + overlays 83GH).

## Antes de mexer no boot

- Anotar a chave de recuperação do BitLocker (conta Microsoft).
- Manter o Windows: ele é a fonte do firmware e de atualizações de BIOS.
