// Controle (0..1) <-> valor bruto do painel. Gama 2,2: metade do controle ≈ 22% da luz.
export const GAMMA = 2.2;
export const LOW = 40;    // ~2% de 2047: abaixo disso o OLED fica praticamente apagado
export const HIGH = 2047; // o painel satura aqui (11 bits reais), apesar de anunciar 16
const clamp = x => Math.min(Math.max(x, 0), 1);
export const toRaw = v => Math.round(LOW + (HIGH - LOW) * Math.pow(clamp(v), GAMMA));
export const fromRaw = raw => Math.pow(clamp((raw - LOW) / (HIGH - LOW)), 1 / GAMMA);
