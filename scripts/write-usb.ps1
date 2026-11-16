# Grava no pendrive (já com a ISO Ubuntu 26.10 arm64+x1e) os arquivos gerados por build-all.sh.
# Uso (na raiz do projeto, PowerShell):  .\scripts\write-usb.ps1 -Drive E
param([Parameter(Mandatory)][string]$Drive)
$root = Resolve-Path (Join-Path $PSScriptRoot "..")
$usb  = "$($Drive.TrimEnd(':')):\"
if (-not (Test-Path "$usb\casper\minimal.standard.live.squashfs")) { throw "$usb não parece um pendrive do Ubuntu (falta casper\)" }
# guarda a camada live original uma única vez
if (-not (Test-Path "$usb\casper\minimal.standard.live.squashfs.orig")) {
  Copy-Item "$usb\casper\minimal.standard.live.squashfs" "$usb\casper\minimal.standard.live.squashfs.orig"
}
$map = @{
  "work\vmlinuz.h4"                           = "casper\vmlinuz.h4"
  "work\vmlinuz.h3"                           = "casper\vmlinuz.h3"
  "work\vmlinuz.slim5x"                       = "casper\vmlinuz.slim5x"
  "work\initrd.qnoc"                          = "casper\initrd.qnoc"
  "work\minimal.standard.live.squashfs.83gh"  = "casper\minimal.standard.live.squashfs"
  "work\minimal.squashfs.83gh"                = "casper\minimal.squashfs"
  "usb\grub.cfg"                              = "boot\grub\grub.cfg"
  "scripts\ubuntoarm-diag.sh"                 = "ubuntoarm-diag.sh"
  "scripts\ubuntoarm-brilho.sh"               = "ubuntoarm-brilho.sh"
  "scripts\ubuntoarm-coleta.sh"               = "ubuntoarm-coleta.sh"
  "scripts\ubuntoarm-reparo.sh"               = "ubuntoarm-reparo.sh"
  "base-overlay\usr\local\sbin\ubuntoarm-protege"                = "ubuntoarm-protege"
  "base-overlay\etc\systemd\system\ubuntoarm-protege.service"    = "ubuntoarm-protege.service"
}
foreach ($src in $map.Keys) {
  $from = Join-Path $root $src; $to = Join-Path $usb $map[$src]
  Copy-Item $from $to -Force
  $ok = (Get-FileHash $from).Hash -eq (Get-FileHash $to).Hash
  "{0,-45} {1}" -f $map[$src], $(if ($ok) { "OK" } else { "DIFERENTE!" })
}
Write-VolumeCache $Drive.TrimEnd(':')
