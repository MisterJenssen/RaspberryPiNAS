import RPi.GPIO as GPIO
import time
import subprocess as sp
import numpy as np

temperatures = np.array([0.0, 0.0, 0.0, 0.0, 0.0])

def map_range(x, in_min, in_max, out_min, out_max):
    return (x - in_min) * (out_max - out_min) // (in_max - in_min) + out_min

def get_temp():        
    return np.sum(temperatures) / len(temperatures)

def measure_temp():    
    if measure_temp.counter >= len(temperatures):
        measure_temp.counter = 0
    
    temperatures[measure_temp.counter] = sp.getoutput("vcgencmd measure_temp|egrep -o '[0-9]*\.[0-9]*'")
#    print("RAW: " + str(temperatures[measure_temp.counter])) 
    
    measure_temp.counter += 1
    
def set_duty_cycle(temperature):
#    print("AVG: " + str(temperature))
    
    if float(temperature) < 50.0:
        dutycycle = 0
    elif float(temperature) > 80.0:
        dutycycle = 100
    else:
        dutycycle = map_range(float(temperature), 50.0, 80.0, 10.0, 100.0)
        
#    print("DC: " + str(dutycycle))     

    p.ChangeDutyCycle(dutycycle)


# initializing GPIO, setting mode to BOARD.
# Default pin of fan is physical pin 8, GPIO14
Fan = 8
GPIO.setmode(GPIO.BOARD)
GPIO.setup(Fan, GPIO.OUT)

p = GPIO.PWM(Fan, 10)
p.start(0)

measure_temp.counter = 0

try:
    while True:
        measure_temp()
        set_duty_cycle(get_temp())
        time.sleep(5)

except KeyboardInterrupt:
    pass
p.stop()
GPIO.cleanup()
