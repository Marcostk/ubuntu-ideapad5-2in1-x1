// Rotação da tela interna pelo D-Bus do Mutter (org.gnome.Mutter.DisplayConfig).
// Sempre assíncrono: dentro do GNOME Shell, o Mutter é o próprio processo e uma chamada síncrona trava.
import Gio from 'gi://Gio';
import GLib from 'gi://GLib';

const BUS = 'org.gnome.Mutter.DisplayConfig';
const PATH = '/org/gnome/Mutter/DisplayConfig';

function call(method, params, type) {
    return new Promise((resolve, reject) => {
        Gio.DBus.session.call(BUS, PATH, BUS, method, params, type ? new GLib.VariantType(type) : null,
            Gio.DBusCallFlags.NONE, -1, null, (conn, res) => {
                try {
                    resolve(conn.call_finish(res));
                } catch (e) {
                    reject(e);
                }
            });
    });
}

// transform: 0 normal, 1 = 90°, 2 = 180°, 3 = 270° (sentido anti-horário, como o Mutter)
export async function setBuiltinTransform(transform) {
    const [serial, monitors, logical] = (await call('GetCurrentState', null)).deepUnpack();
    const builtin = new Set(monitors.filter(([, , props]) => props['is-builtin']?.deepUnpack())
        .map(([[connector]]) => connector));
    const modeOf = connector => {
        const [, modes] = monitors.find(([[c]]) => c === connector);
        return modes.find(([, , , , , , p]) => p['is-current']?.deepUnpack())[0];
    };
    const config = logical.map(([x, y, scale, t, primary, specs]) => [
        x, y, scale,
        specs.some(([c]) => builtin.has(c)) ? transform : t,
        primary,
        specs.map(([c]) => [c, modeOf(c), {}]),
    ]);
    // método 1 = temporário: volta ao normal no próximo login
    await call('ApplyMonitorsConfig',
        new GLib.Variant('(uua(iiduba(ssa{sv}))a{sv})', [serial, 1, config, {}]));
}

export async function getBuiltinTransform() {
    const [, monitors, logical] = (await call('GetCurrentState', null)).deepUnpack();
    const builtin = monitors.find(([, , props]) => props['is-builtin']?.deepUnpack())?.[0][0];
    return logical.find(([, , , , , specs]) => specs.some(([c]) => c === builtin))?.[3] ?? 0;
}
