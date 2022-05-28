from __future__ import print_function
import json
import paho.mqtt.publish as publish
import RPi.GPIO as GPIO
import time
import requests
import urllib3

channelID = "1666700"
writeApiKey = "843OJGZ6WIC4XU3R"
readApiKey="5A1VUF6SRJA4NV1N"
URL2="https://api.thingspeak.com/channels/1675633/fields/1.json?api_key="+readApiKey+"&results=1"
URL3="https://api.thingspeak.com/channels/1675633/fields/2.json?api_key="+readApiKey+"&results=1"
URL1="https://api.thingspeak.com/update?api_key="+writeApiKey
tTransport = "websockets"
tPort = 80
mqtt_client_ID="Ng4DDQc8DCgTEzIqHDUFBis"
mqtt_username="Ng4DDQc8DCgTEzIqHDUFBis"
mqtt_password="VoTWrZBvHg6r0YNUlwUI7rER"
# Create the topic string
topic = "channels/" + channelID + "/publish"
mqttHost="mqtt3.thingspeak.com"
IL1=4
IL2=5
IL3=6

IU1=10
IU2=11

Trig=2
Echo=3

trig1=7
echo1=8
#
GPIO.setmode(GPIO.BCM)
GPIO.setwarnings(False)

GPIO.setup(IL1, GPIO.IN)
GPIO.setup(IL2, GPIO.IN)
GPIO.setup(IL3, GPIO.IN)
GPIO.setup(IU1, GPIO.IN)
GPIO.setup(IU2, GPIO.IN)


GPIO.setup(Trig, GPIO.OUT, initial=GPIO.LOW)
GPIO.setup(Echo, GPIO.IN)
GPIO.setup(trig1, GPIO.OUT, initial=GPIO.LOW)
GPIO.setup(echo1, GPIO.IN)
time.sleep(1)

sl1=0.1#Distance between IR1 and IR2 in "m"
sl2=0.1#Distance between IR2 and IR3 in "m"

def get_HYSRF05(Trig,Echo):
    GPIO.output(Trig, GPIO.HIGH)
    time.sleep(0.000015)
    GPIO.output(Trig, GPIO.LOW)
    while not GPIO.input(Echo):
        pass
    t1 = time.time()
    while GPIO.input(Echo):
        pass
    t2 = time.time()
    return (t2 - t1) * 340 / 2

def calculation(r1,r2,r3,s1,s2):
    cn = 0
    speed=0
    length=0
    if get_HYSRF05(Trig,Echo)<2 :
        while not GPIO.input(r1):
            pass
        t1 = time.time()
        cn+=1
        while GPIO.input(r1):
            pass
        t2= time.time()
        t1l=t2-t1#Car length time
        while not GPIO.input(r2):
            pass
        t3 = time.time()
        cn+=1
        while GPIO.input(r2):
            pass
        t4= time.time()
        t2l=t4-t3#Car length time
        while not GPIO.input(r3):
            pass
        t5 = time.time()
        cn+=1
        while GPIO.input(r3):
            pass
        t6= time.time()
        t3l=t6-t5#Car length time
        speed=(((s1/(t3-t1))+(s2/(t5-t3))+((s1+s2)/(t5-t1)))/3)
        length = ((speed * (t1l+t2l+t3l)) / 3)
    return [speed,length]


while True:
    llist=calculation(IL1,IL2,IL3,sl1,sl2)
    if llist[0]<250 and llist[1]<10:
        tPayload = "field1=" + str(llist[0]) + "&field2=" + str(llist[1])+"&field3=" + str(get_HYSRF05(trig1,echo1))
        print(llist[0], llist[1],get_HYSRF05(trig1,echo1))
        try:
            publish.single(topic, payload=tPayload, hostname=mqttHost, port=tPort, transport=tTransport,
                           client_id=mqtt_client_ID,
                           auth={'username': mqtt_username, 'password': mqtt_password})
        except KeyboardInterrupt:
            GPIO.cleanup()

    time.sleep(0.5)
        # light_data1 = requests.get(url=URL2)
        # light_data2 = requests.get(url=URL3)
        # llight = json.loads(light_data1.content.decode("utf-8"))['feeds'][0]['field1']
        # ulight = json.loads(light_data2.content.decode("utf-8"))['feeds'][0]['field2']
        # if llight==0:
        #     GPIO.output(LL1, GPIO.HIGH)
        #     GPIO.output(LL2, GPIO.LOW)
        #     GPIO.output(LL3, GPIO.LOW)
        # elif llight==1:
        #     GPIO.output(LL1, GPIO.LOW)
        #     GPIO.output(LL2, GPIO.HIGH)
        #     GPIO.output(LL3, GPIO.LOW)
        #     time.sleep(5)
        # elif llight == 2:
        #     GPIO.output(LL1, GPIO.LOW)
        #     GPIO.output(LL2, GPIO.LOW)
        #     GPIO.output(LL3, GPIO.HIGH)
        #     time.sleep(5)
        # if ulight == 0:
        #     GPIO.output(LL1, GPIO.HIGH)
        #     GPIO.output(LL2, GPIO.LOW)
        #     time.sleep(5)
        # elif ulight == 1:
        #     GPIO.output(LL1, GPIO.LOW)
        #     GPIO.output(LL2, GPIO.HIGH)

