// Liga/desliga o teclado e o touchpad internos pelo atributo "inhibited" do kernel
// (liberado para o usuário pela regra /etc/udev/rules.d/70-ubuntoarm-tablet.rules).
import Gio from 'gi://Gio';
import GLib from 'gi://GLib';

const INTERNAL = /^hid-over-i2c (048D:8987|04F3:327E)/; // teclado ITE e touchpad Elan do 83GH

export function internalInputs() {
    const found = [];
    const dir = Gio.File.new_for_path('/sys/class/input');
    for (const info of dir.enumerate_children('standard::name', Gio.FileQueryInfoFlags.NONE, null)) {
        const name = info.get_name();
        if (!name.startsWith('input'))
            continue;
        try {
            const [, bytes] = GLib.file_get_contents(`/sys/class/input/${name}/name`);
            if (INTERNAL.test(new TextDecoder().decode(bytes).trim()))
                found.push(`/sys/class/input/${name}/inhibited`);
        } catch {}
    }
    return found;
}

// sysfs: escreve no próprio arquivo (sem arquivo temporário + rename, que o sysfs não aceita)
export function setInhibited(on) {
    const errors = [];
    for (const path of internalInputs()) {
        try {
            const out = Gio.File.new_for_path(path).append_to(Gio.FileCreateFlags.NONE, null);
            out.write_all(new TextEncoder().encode(on ? '1' : '0'), null);
            out.close(null);
        } catch (e) {
            errors.push(`${path}: ${e.message}`);
        }
    }
    return errors;
}
