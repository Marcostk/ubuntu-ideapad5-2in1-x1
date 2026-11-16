# Copia do DriverStore do Windows o firmware Qualcomm do notebook para firmware\windows-driverstore.
# O firmware é assinado para o aparelho e licenciado pela Qualcomm/Lenovo: não redistribua.
# Uso (na raiz do projeto, PowerShell):  .\scripts\extract-firmware.ps1
$ds  = "C:\Windows\System32\DriverStore\FileRepository"
$dst = Join-Path $PSScriptRoot "..\firmware\windows-driverstore"
New-Item -ItemType Directory -Force $dst | Out-Null
$dirs = Get-ChildItem $ds -Directory | Where-Object {
  $_.Name -match '^(qcdx8380|qcdxext_crd8380|qcnspmcdm_ext_cdsp8380|qcsubsys|qcwlan|qcbt|qcadcm|qcasd)'
}
foreach ($d in $dirs) {
  $t = Join-Path $dst $d.Name
  New-Item -ItemType Directory -Force $t | Out-Null
  Get-ChildItem $d.FullName -File |
    Where-Object { $_.Extension -in '.mbn', '.elf', '.jsn', '.bin', '.inf' } |
    Copy-Item -Destination $t
}
$need = 'qcadsp8380.mbn','adsp_dtbs.elf','qccdsp8380.mbn','cdsp_dtbs.elf','qcdxkmsucpurwa.mbn','qcvss8380_pa.mbn'
foreach ($n in $need) {
  if (-not (Get-ChildItem $dst -Recurse -Filter $n)) { Write-Warning "faltou $n" }
}
"Firmware copiado para $((Resolve-Path $dst).Path)"
