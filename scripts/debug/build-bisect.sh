#!/bin/bash
# Kernels de teste para achar o bloco do SoC que reseta o 83GH: cada um desliga um grupo de nós no DTB.
# Gera work/vmlinuz.t1 .. t13. Rodar como root no WSL, a partir da raiz do projeto.
set -euo pipefail
B=/root/build; DTB=work/x1p42100-lenovo-ideapad-5-2in1.dtb
declare -A G
G[t1]="pcie@1bf8000 pcie@1c08000 phy@1bfc000 phy@1c0e000"                                         # PCIe (Wi-Fi, NVMe)
G[t2]="geniqup@8c0000 geniqup@ac0000 geniqup@bc0000 dma-controller@800000 dma-controller@a00000 dma-controller@b00000"  # QUP (I2C/UART)
G[t3]="usb@a000000 usb@a200000 usb@a400000 usb@a600000 usb@a800000 phy@88e0000 phy@88e1000 phy@88e2000 phy@88e3000 phy@88e5000 phy@fd3000 phy@fd5000 phy@fd9000 phy@fda000 phy@fde000 phy@fdf000"  # USB
G[t4]="display-subsystem@ae00000 gpu@3d00000 video-codec@aa00000 remoteproc@32300000 remoteproc@6800000 soundwire@6ad0000 soundwire@6b10000 soundwire@6d30000 mmc@8804000"  # vídeo, GPU, DSPs, som, microSD
# rodada 2: nada acima isolado resolveu; testar blocos centrais e a união de t1..t4
G[t5]="soc@0/iommu@15000000 soc@0/iommu@3da0000"   # SMMUs
G[t6]="firmware/scmi"                               # SCMI (frequência da CPU via CPUCP)
G[t7]="firmware/scm"                                # SCM (firmware seguro / TZ)
G[t8]="${G[t1]} ${G[t2]} ${G[t3]} ${G[t4]}"
for t in t1 t2 t3 t4; do G[$t]=$(for n in ${G[$t]}; do echo -n "soc@0/$n "; done); done
G[t8]=$(for n in ${G[t8]}; do echo -n "soc@0/$n "; done)
# rodada 3: t9 = PDC com compatible do Purwa (sem o workaround do X1E); t10 = t5..t8 juntos (só a interconexão sobra)
G[t9]=""
G[t10]="${G[t5]} ${G[t6]} ${G[t7]} ${G[t8]}"
# rodada 5: t10 reiniciou logo após o probe de interconnect@1600000; o próximo é o system-noc
G[t11]="${G[t10]} soc@0/interconnect@1680000"
# rodada 8 (com initrd.qnoc): o log para ao subir o pcie@1c08000 (Wi-Fi). t12 = sem PCIe 4; t13 = sem OPP nos PCIe
G[t12]="soc@0/pcie@1c08000 soc@0/phy@1c0e000"
G[t13]=""
for t in t1 t2 t3 t4 t5 t6 t7 t8 t9 t10 t11 t12 t13; do
  cp "$DTB" "$B/$t.dtb"
  for n in ${G[$t]}; do fdtput -t s "$B/$t.dtb" "/$n" status disabled; done
  [ $t = t9 ] && fdtput -t s "$B/$t.dtb" /soc@0/interrupt-controller@b220000 compatible qcom,x1p42100-pdc qcom,pdc \
    && echo "t9: pdc = $(fdtget "$B/$t.dtb" /soc@0/interrupt-controller@b220000 compatible)"
  if [ $t = t13 ]; then
    for n in pcie@1c08000 pcie@1bf8000; do
      if fdtget "$B/$t.dtb" "/soc@0/$n" operating-points-v2 >/dev/null 2>&1; then
        fdtput -d "$B/$t.dtb" "/soc@0/$n" operating-points-v2 && echo "t13: OPP removida de $n"
      else echo "t13: $n sem OPP"; fi
    done
  fi
  python3 -I scripts/add-dtb-to-uki.py work/usb/vmlinuz "$B/$t.dtb" "work/vmlinuz.$t" >/dev/null
  echo "$t: $(for n in ${G[$t]}; do fdtget "$B/$t.dtb" "/$n" status; done | sort | uniq -c | xargs)"
done
