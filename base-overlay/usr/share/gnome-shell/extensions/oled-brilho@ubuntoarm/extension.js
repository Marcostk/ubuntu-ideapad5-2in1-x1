// Brilho do OLED Samsung ATNA40CT01 do IdeaPad 5 2-in-1 (83GH).
// O painel diz aceitar 16 bits (0-65535) pelo AUX do eDP, mas satura em ~2047 (11 bits reais;
// o DT do jglathe usa max-brightness = <2047>, que o kernel do Ubuntu ignora). O GNOME Shell 51
// mapeia o controle linearmente em 655..65535, então só os primeiros ~2% do controle faziam efeito,
// e o Mutter recusa valores abaixo de 655 (= 32% da luz real). Aqui o controle grava direto pelo
// logind (o mesmo caminho do Mutter, sem root) na faixa real, com curva gama.
import Gio from 'gi://Gio';
import GLib from 'gi://GLib';
import * as Main from 'resource:///org/gnome/shell/ui/main.js';
import {Extension} from 'resource:///org/gnome/shell/extensions/extension.js';
import {toRaw, fromRaw} from './curve.js';

const DEVICE = 'dp_aux_backlight';
const SYSFS = `/sys/class/backlight/${DEVICE}/brightness`;

function readRaw() {
    try {
        const [, bytes] = GLib.file_get_contents(SYSFS);
        return parseInt(new TextDecoder().decode(bytes), 10);
    } catch {
        return 2047;
    }
}

// valores que esta extensão gravou por último (controle ou esmaecimento do GNOME). O Mutter avisa o Shell de toda
// mudança no painel; sem isso o Shell trataria o próprio esmaecimento como mudança externa e o adotaria.
// Vários, e não só o último: ao arrastar o controle, avisos de gravações anteriores chegam atrasados.
const written = [];

function writeRaw(raw) {
    written.push(raw);
    if (written.length > 16)
        written.shift();
    Gio.DBus.system.call('org.freedesktop.login1', '/org/freedesktop/login1/session/auto',
        'org.freedesktop.login1.Session', 'SetBrightness',
        new GLib.Variant('(ssu)', ['backlight', DEVICE, raw]),
        null, Gio.DBusCallFlags.NONE, -1, null,
        (conn, res) => {
            try {
                conn.call_finish(res);
            } catch (e) {
                console.warn(`oled-brilho: SetBrightness ${raw} falhou: ${e.message}`);
            }
        });
}

export default class OledBrilho extends Extension {
    enable() {
        this._monitorManager = global.backend.get_monitor_manager();
        // as escalas por monitor são recriadas a cada mudança de monitores; a classe é a mesma
        this._monitorManager.connectObject('monitors-changed', () => this._patch(), this);
        this._patch();
    }

    _patch() {
        const scales = Main.brightnessManager?.scales ?? [];
        if (!this._proto && scales.length) {
            const proto = Object.getPrototypeOf(scales[0]);
            this._proto = proto;
            this._orig = {
                get: proto._getRelativeBrightness,
                set: proto._setRelativeBrightness,
                sync: proto.syncWithBacklight,
            };
            proto._getRelativeBrightness = () => fromRaw(readRaw());
            proto._setRelativeBrightness = (_b, v) => writeRaw(toRaw(v));
            // true = mudança externa (o Shell adota o valor e cancela o esmaecimento); as nossas não contam
            proto.syncWithBacklight = function () {
                const raw = readRaw();
                if (written.includes(raw))
                    return false;
                this.value = fromRaw(raw);
                return true;
            };
        }
        // reposiciona o controle a partir do brilho real do painel (só adota se não fomos nós que gravamos)
        for (const s of scales)
            s.syncWithBacklight();
    }

    disable() {
        this._monitorManager?.disconnectObject(this);
        this._monitorManager = null;
        if (this._proto) {
            this._proto._getRelativeBrightness = this._orig.get;
            this._proto._setRelativeBrightness = this._orig.set;
            this._proto.syncWithBacklight = this._orig.sync;
        }
        this._proto = this._orig = null;
    }
}
