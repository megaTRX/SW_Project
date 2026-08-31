import spidev
import time

spi = spidev.SpiDev()
spi.open(10,0)
spi.max_speed_hz = 1000000

def read_adc(ch):
    adc = spi.xfer2([1, (8+ch)<<4, 0])
    return ((adc[1] & 3) << 8) + adc[2]

while True:
    print(read_adc(0))
    time.sleep(1)
