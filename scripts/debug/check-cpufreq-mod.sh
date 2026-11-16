#!/bin/bash
# Procura os módulos de cpufreq SCMI na imagem e seus aliases.
grep -E 'scmi-cpufreq|scmi_cpufreq|scmi_perf_domain|scmi-perf-domain' /root/build/minimal.list | sed 's|squashfs-root||'
A=$(ls /root/build/scmi/usr/lib/modules/*/modules.alias 2>/dev/null)
[ -n "$A" ] && grep -i -E 'scmi' "$A" | head
