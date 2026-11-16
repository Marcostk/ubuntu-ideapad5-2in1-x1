// Modo tablet manual para o IdeaPad 5 2-in-1 (83GH). Os sensores de dobradiça e orientação ficam no
// ADSP e derrubam a placa no Linux (HMAC do registro de sensores), então não há detecção automática.
import Clutter from 'gi://Clutter';
import GObject from 'gi://GObject';
import Gio from 'gi://Gio';
import GLib from 'gi://GLib';
import St from 'gi://St';
import * as Main from 'resource:///org/gnome/shell/ui/main.js';
import * as PanelMenu from 'resource:///org/gnome/shell/ui/panelMenu.js';
import * as PopupMenu from 'resource:///org/gnome/shell/ui/popupMenu.js';
import {QuickMenuToggle, SystemIndicator} from 'resource:///org/gnome/shell/ui/quickSettings.js';
import {Extension} from 'resource:///org/gnome/shell/extensions/extension.js';
import {setInhibited} from './inputs.js';
import {setBuiltinTransform, getBuiltinTransform} from './display.js';

const A11Y = 'org.gnome.desktop.a11y.applications';
const ROTATIONS = [
    [0, 'Normal'],
    [1, 'Retrato (90°)'],
    [2, 'Invertida (180°)'],
    [3, 'Retrato (270°)'],
];

// Botão na barra superior que abre/fecha o teclado na tela. Serve para apps que não avisam o GNOME quando um
// campo de texto ganha foco (X11, Chromium/Electron sem IME do Wayland): as teclas vão por teclado virtual.
// Não pode pegar o foco: se o foco sair do campo de texto, o GNOME fecha o teclado na hora.
const KeyboardButton = GObject.registerClass(
class KeyboardButton extends PanelMenu.Button {
    _init() {
        super._init(0.0, 'Teclado na tela', true);
        this.can_focus = false;
        this.add_child(new St.Icon({icon_name: 'input-keyboard-symbolic', style_class: 'system-status-icon'}));
        const click = new Clutter.ClickGesture();
        click.connect('recognize', () => {
            if (Main.keyboard.visible)
                Main.keyboard.close();
            else
                Main.keyboard.open(Main.layoutManager.focusIndex);
        });
        this.add_action(click);
    }
});

// O Mutter só pede o teclado na tela quando o app manda um segundo "enable" com o campo já focado: apps GTK
// fazem isso a cada toque, Chromium/Electron (Brave, app do Claude) mandam um só. No modo tablet, abre o
// teclado sempre que um campo de texto de qualquer app ganha foco. O vfunc_focus_in do Shell chama
// this._context.focus_in() (contexto IBus) em JavaScript, então dá para envolver esse método no objeto.
class FocusOpensKeyboard {
    constructor() {
        this._ctx = Main.inputMethod?._context ?? null;
        if (!this._ctx) {
            console.warn('tablet@ubuntoarm: sem contexto IBus; o teclado não vai abrir sozinho (use o botão)');
            return;
        }
        const orig = this._orig = this._ctx.focus_in;
        const hook = this;
        this._ctx.focus_in = function (...args) {
            const ret = orig.apply(this, args);
            if (hook._ctx) {
                GLib.idle_add_once(GLib.PRIORITY_DEFAULT_IDLE,
                    () => Main.keyboard.open(Main.layoutManager.focusIndex));
            }
            return ret;
        };
    }

    destroy() {
        // "delete" não remove a propriedade de um objeto GObject: reatribui o método original
        if (this._ctx)
            this._ctx.focus_in = this._orig;
        this._ctx = null;
    }
}

const TabletToggle = GObject.registerClass(
class TabletToggle extends QuickMenuToggle {
    _init() {
        super._init({title: 'Modo tablet', iconName: 'input-tablet-symbolic', toggleMode: true});
        this._a11y = new Gio.Settings({schema_id: A11Y});
        this.menu.setHeader('input-tablet-symbolic', 'Modo tablet', 'Girar a tela');
        this._items = ROTATIONS.map(([t, label]) => {
            const item = new PopupMenu.PopupMenuItem(label);
            item.connect('activate', () => this._rotate(t));
            this.menu.addMenuItem(item);
            return [t, item];
        });
        this.menu.connect('open-state-changed', (_m, open) => open && this._syncRotation());
        this.connect('notify::checked', () => this._apply());
    }

    _apply() {
        const on = this.checked;
        const errors = setInhibited(on);
        // teclado na tela só no modo tablet: com o teclado físico ativo, tocar num campo não deve abri-lo
        this._a11y.set_boolean('screen-keyboard-enabled', on);
        this.subtitle = on ? 'Teclado e touchpad desligados' : null;
        if (on && !this._kbButton) {
            this._kbButton = new KeyboardButton();
            Main.panel.addToStatusArea('ubuntoarm-teclado-na-tela', this._kbButton, 0, 'right');
        } else if (!on && this._kbButton) {
            this._kbButton.destroy();
            this._kbButton = null;
        }
        this._focusHook?.destroy();
        this._focusHook = on ? new FocusOpensKeyboard() : null;
        if (errors.length)
            Main.notifyError('Modo tablet', `Não consegui ${on ? 'desligar' : 'religar'} o teclado/touchpad:\n${errors.join('\n')}`);
    }

    async _rotate(transform) {
        try {
            await setBuiltinTransform(transform);
        } catch (e) {
            Main.notifyError('Modo tablet', `Não consegui girar a tela: ${e.message}`);
        }
        this._syncRotation();
    }

    async _syncRotation() {
        try {
            const current = await getBuiltinTransform();
            for (const [t, item] of this._items)
                item.setOrnament(t === current ? PopupMenu.Ornament.CHECK : PopupMenu.Ornament.NONE);
        } catch {}
    }

    destroy() {
        // nunca deixar o notebook sem teclado: ao desativar/sair, religa tudo
        if (this.checked) {
            this.checked = false;
            this._apply();
        }
        super.destroy();
    }
});

export default class TabletExtension extends Extension {
    enable() {
        setInhibited(false); // se o shell caiu com o modo ligado, o teclado volta
        // o modo tablet começa desligado, então o teclado na tela também
        new Gio.Settings({schema_id: A11Y}).set_boolean('screen-keyboard-enabled', false);
        this._indicator = new SystemIndicator();
        this._indicator.quickSettingsItems.push(new TabletToggle());
        Main.panel.statusArea.quickSettings.addExternalIndicator(this._indicator);
    }

    disable() {
        this._indicator.quickSettingsItems.forEach(item => item.destroy());
        this._indicator.destroy();
        this._indicator = null;
    }
}
