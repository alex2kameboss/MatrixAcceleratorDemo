# pip install pyserial

import serial
import time

ser = serial.Serial('/dev/ttyUSB1', 115200)

image_width = 640
image_height = 480

# send data
ser.write(f"$START\r".encode('utf-8'))
time.sleep(0.1)
ser.write(f"$WIDTH{image_width}\r".encode('utf-8'))
time.sleep(0.1)
ser.write(f"$HEIGHT{image_height}\r".encode('utf-8'))
time.sleep(0.1)
ser.write(f"$DATA_START\r".encode('utf-8'))
time.sleep(0.1)
print("Send image")
for i in range(image_height):
    for j in range(image_width):
        ser.write(b'abcd')
        #time.sleep(0.1)
time.sleep(0.1)
ser.write(f"$DATA_END\r".encode('utf-8'))

# read data
print("Wait response")
while True:
    response = ser.readline().decode().strip()
    print(response)