#!/bin/bash
# Confere se as funções que o módulo qnoc modificado usa estão exportadas no kernel 7.3.0-15 do Ubuntu.
H=/root/build/hdr/usr/src/linux-headers-7.3.0-15-qcom-x1e
[ -f "$H/Module.symvers" ] || H=$(dirname "$(find /root/build/hdr -name Module.symvers | head -1)")
echo "headers: $H"
for s in qcom_icc_set qcom_icc_pre_aggregate qcom_icc_aggregate qcom_icc_xlate_extended qcom_icc_bcm_init \
         of_bcm_voter_get qcom_icc_bcm_voter_add qcom_icc_rpmh_probe qcom_icc_rpmh_remove \
         icc_provider_init icc_provider_register icc_node_create_dyn icc_node_set_name icc_node_add \
         icc_link_nodes icc_nodes_remove icc_node_destroy icc_sync_state; do
  printf '%-28s %s\n' "$s" "$(awk -v s="$s" '$2==s {print $3, $4; f=1} END {if (!f) print "NÃO EXPORTADO"}' "$H/Module.symvers")"
done
ls "$H/include/linux/interconnect-provider.h" >/dev/null && echo "interconnect-provider.h ok"
