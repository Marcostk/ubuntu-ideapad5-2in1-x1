# UbuntoARM: lê o acelerômetro pelo Sensor Core (libssc). Uso: python3 -u ssc_accel.py
import gi, sys
gi.require_version('SSC', '2'); from gi.repository import SSC, GLib
print('procurando acelerômetro...')
try:
    s = SSC.SensorAccelerometer.new_sync(None)
except GLib.Error as e:
    print('new_sync falhou:', e.message); sys.exit(1)
print('achou')
for p in ('name', 'vendor', 'data-type', 'available', 'mount-matrix', 'sample-rate'):
    try: print(' ', p, '=', s.get_property(p))
    except Exception as e: print(' ', p, '?', e)
n = [0]
def m(*a):
    n[0] += 1
    if n[0] <= 5: print('medida:', a[1:])
s.connect('measurement', m)
print('open:', s.open_sync(None))
loop = GLib.MainLoop(); GLib.timeout_add_seconds(4, loop.quit); loop.run()
print('amostras:', n[0]); s.close_sync(None)
