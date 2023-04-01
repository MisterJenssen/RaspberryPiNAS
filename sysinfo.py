#!/usr/bin/python3
# -*- coding: utf-8 -*-
# Copyright (c) 2014-2020 Richard Hull and contributors
# See LICENSE.rst for details.
# PYTHON_ARGCOMPLETE_OK


import os
import sys
import time
import atexit
from pathlib import Path
from datetime import datetime
from demo_opts import get_device
from luma.core.render import canvas
from PIL import ImageFont
import psutil
import subprocess as sp
from rpi_ws281x import PixelStrip, Color
import argparse

# LED strip configuration:
LED_COUNT = 4        # Number of LED pixels.
LED_PIN = 18          # GPIO pin connected to the pixels (18 uses PWM!).
# LED_PIN = 10        # GPIO pin connected to the pixels (10 uses SPI /dev/spidev0.0).
LED_FREQ_HZ = 800000  # LED signal frequency in hertz (usually 800khz)
LED_DMA = 10          # DMA channel to use for generating signal (try 10)
LED_BRIGHTNESS = 255  # Set to 0 for darkest and 255 for brightest
LED_INVERT = False    # True to invert the signal (when using NPN transistor level shift)
LED_CHANNEL = 0       # set to '1' for GPIOs 13, 19, 41, 45 or 53

COLOR_RED = Color(30, 0, 0)
COLOR_ORANGE = Color(30, 10, 0)
COLOR_GREEN = Color(0, 30, 0)
COLOR_BLUE = Color(0, 0, 30)
COLOR_OFF = Color(0, 0, 0)


def bytes2human(n):
    """
    >>> bytes2human(10000)
    '9K'
    >>> bytes2human(100001221)
    '95M'
    """
    symbols = ('K', 'M', 'G', 'T', 'P', 'E', 'Z', 'Y')
    prefix = {}
    for i, s in enumerate(symbols):
        prefix[s] = 1 << (i + 1) * 10
    for s in reversed(symbols):
        if n >= prefix[s]:
            value = int(float(n) / prefix[s])
            return '%s%s' % (value, s)
    return "%sB" % n


def cpu_usage():
    # load average
    av1, av2, av3 = os.getloadavg()
    return "Ld: %.1f %.1f %.1f " % (av1, av2, av3)


#def uptime_usage():
    # uptime, Ip
#    uptime = datetime.now() - datetime.fromtimestamp(psutil.boot_time())
#    ip = sp.getoutput("hostname -I").split(' ')[0]
#    return "Up: %s,IP:%s" % (uptime, ip)

def get_ip_address():
    ip = sp.getoutput("hostname -I").split(' ')[0]
    return "%s" % (ip)


def get_stats_ip_address_string(ip_address):
    return "IP: %s" % (ip_address)    


def mem_usage():
    usage = psutil.virtual_memory()
    return "Mem:  %s %.1f%%" \
        % (bytes2human(usage.used), usage.percent)


def disk_usage(dir):
    usage = psutil.disk_usage(dir)
    return "NAS:  %s %.1f%%" \
        % (bytes2human(usage.used), usage.percent)


def get_cpu_temperature():
    return sp.getoutput("vcgencmd measure_temp|egrep -o '[0-9]*\.[0-9]*'")
    

def get_stats_cpu_temperature_string(temperature):
    return "Temp: %s°" % (temperature)


# def network(iface):
#     stat = psutil.net_io_counters(pernic=True)[iface]
#    return "%s: Tx%s, Rx%s" % \
#            (iface, bytes2human(stat.bytes_sent), bytes2human(stat.bytes_recv))


def print_stats(device, ip_address_str, cpu_usage_str, cpu_temperature_str, mem_usage_str, disk_usage_str):
    # use custom font
    font_path = '/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf'
    font2 = ImageFont.truetype(font_path, 11)

    with canvas(device) as draw:
        draw.text((0, 1), ip_address_str, font=font2, fill="white")
        draw.text((0, 12), cpu_usage_str, font=font2, fill="white")
        draw.text((0, 24), cpu_temperature_str, font=font2, fill="white")
        draw.text((0, 36), mem_usage_str, font=font2, fill="white")
        draw.text((0, 48), disk_usage_str, font=font2, fill="white")


def setColor(strip, color, wait_ms=1000):    
    for i in range(strip.numPixels()):
        strip.setPixelColor(i, color)
    strip.show()
    time.sleep(wait_ms / 1000.0)


def checkValidIP(ip_address, color):
    if not ip_address:
        return COLOR_BLUE
    else:
        return color
    

def controlMoodLight(ip_address, temperature):
    if float(temperature) > 80.0:
        color = COLOR_RED
    elif float(temperature) > 60.0:    
        color = checkValidIP(ip_address, COLOR_ORANGE)
    else:
        color = checkValidIP(ip_address, COLOR_GREEN)
    setColor(strip, color, 0)


def exitHandler():
    print('Stopping process')
    setColor(strip, Color(0, 0, 0), 100)
    

# Main program logic follows:
if __name__ == '__main__':
    # Process arguments
    parser = argparse.ArgumentParser()
    parser.add_argument('-c', '--clear', action='store_true', help='clear the display on exit')
    args = parser.parse_args()
    
    # Get LCD display
    device = get_device()

    # Create NeoPixel object with appropriate configuration.
    strip = PixelStrip(LED_COUNT, LED_PIN, LED_FREQ_HZ, LED_DMA, LED_INVERT, LED_BRIGHTNESS, LED_CHANNEL)
    
    # Intialize the library (must be called once before other functions).
    strip.begin()
    
    # Configure exit handler
    atexit.register(exitHandler)

    print('Press Ctrl-C to quit.')

    print('Starting process')
    while True:
        ip = get_ip_address()
        temperature = get_cpu_temperature()            
        
        print_stats(device,
                    get_stats_ip_address_string(ip),
                    cpu_usage(),
                    get_stats_cpu_temperature_string(temperature),
                    mem_usage(),
                    disk_usage('/mnt'))
        
        controlMoodLight(ip, temperature)
        time.sleep(5)
