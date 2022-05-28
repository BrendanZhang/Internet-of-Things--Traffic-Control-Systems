# Internet-of-Things--Traffic-Control-Systems
研究生预科时期RPS项目
1.2	Design background and aim
The road is one of the greatest inventions of all time. It connects the different cities of the world, large and small, and it is an important part of what makes up a country. However, as time goes on, the number of vehicles travelling on the roads has gradually increased, which has led to a gradual rise in the probability of car accidents on the roads. Although sophisticated traffic laws have greatly improved the situation, the design of traffic lights is still very old and only changes at regular intervals depending on the time of day, which cannot be changed in real time. Some areas now use push buttons as a trigger for pedestrians to cross the road, but this is very unfriendly to the disabled and even the blind is unaware of it.

In response to the above. The aim of this project is to develop MATLAB code that integrates with IoT protocols and connects to devices to form a simple defined system that uses inexpensive components such as a Raspberry Pi board and other suitable sensors to form a contextually designed traffic control system that can measure the speed of vehicles moving on the road and thus change the traffic lights.
2.	Methodology
There are 4 key parts to an IoT system:
1. Collect data (sensors)
2. Share the data (transmit from the sensor to other devices)
3. Process the data (a computer program uses the input to make decision on actions)
4. Act on the data (a connected device acts on an instruction given)

My sensor of choice was the SHARP GP2Y0A41SKOF infrared sensor and the HC-SR04 ultrasonic distance measurement module. The initial data collection and calculations were carried out using Raspberry Pi running python and the results were then sent to Thingspeak using the MQTT protocol as a relay station for the data. This allows other devices to use Matlab to obtain the data from Thingspeak, process it and display it using the Automated Driving Toolbox, before sending it to the LEDs to make the appropriate traffic light changes.
![image](https://user-images.githubusercontent.com/106435726/170827163-3b01e6e7-3b34-44b2-8faa-f328568f4306.png)
![image](https://user-images.githubusercontent.com/106435726/170827176-beff7755-1b77-4223-97ac-5a91ac3c13bd.png)
There are 3 main parts: the python program, the MATLAB program and the hardware build.
3.1	Python Result
The python program runs inside the Raspberry Pi and is responsible for collecting data from all the sensors as well as doing the initial processing and sending it to thingspeak using MQTT.

The python program on the computer calls the python in the Raspberry Pi via ssh, the computer is only responsible for calling and starting the program.

The first step in the python program is to set the channelID, readApiKey, writeApiKey and MQTT account password of the created Thingspeak to facilitate later calls. Then the corresponding sensor call methods are created, starting with the ultrasonic call method, which returns the distance of the ultrasonic sensor from the front plane by reading the duration of the returned waveform and combining it with the speed of sound propagation in the air. Then comes the infrared sensor, as the Raspberry Pi all interfaces are digital interfaces no analogue interfaces, so infrared can not return data directly, and there is a lot of error. In this part of the three infrared as a group, read them in turn to read the data time and data disappearance time, here combined with the distance between the three sensors can be calculated through the vehicle speed and length, in this method to add read an ultrasonic data which can be very effective in reducing part of the infrared error. This method outputs the speed and length of the vehicle. Finally, the main program calls the above method to obtain the speed and length of the passing vehicle and to obtain an ultrasonic distance data in the direction of the pedestrian, and sends these 3 data to the first 3 channels of my thingspeak. The overall program runs once every 1 second.
3.2	MATLAB Result
MATLAB is responsible for the calculation of traffic light changes, the animated presentation of road conditions, and the control of traffic light changes.

The animation scene is first constructed in MATLAB, while some basic data is entered and the Raspberry Pi is connected. Then the loop is entered and the default state of the traffic lights is set: because it is a motorway it is mainly passing vehicles, so the light for the direction of the car (CL) is green and the light for the direction of the person (PL) is red. This is to prevent data loss and also to record the time point of the latest data read, which is to prevent the same data being recycled several times. The 10 sets of data are then filtered to ensure that the valid data left is that of the vehicles that are passing at that time. This is followed by a determination of the vehicles and pedestrians on the road.
1. If there are no people or cars passing, the next cycle is carried out directly.
2. If there are people and no cars, change the CL to yellow to remind the vehicles coming when the pedestrians pass to slow down, PL to green and the pedestrians pass, with a simultaneous animated demonstration of a pedestrian passing quickly. Like figure 1.
![image](https://user-images.githubusercontent.com/106435726/170827221-f7ac6484-9c07-422e-9a69-a80564899605.png)
3. If there are cars and no people, keep the traffic light unchanged and an animated demonstration of each car, keeping the same time difference as in reality as well as the number.
4. If there are cars and people, the state of the cars is calculated, first by calculating the distance from each car to the pedestrian, then by calculating the distance the car would travel at the time the pedestrian passes the road if it maintained its original speed, and the distance the car would travel if it were to decelerate uniformly.
4.1 If there is a vehicle at a deceleration time greater than the distance the vehicle is from the pedestrian then this means that if the pedestrian crosses the road at this time even if the vehicle slows down they will be hit, so the default state is maintained, the vehicle passes normally and the pedestrian waits, and an animation is performed.
4.2 If the distance travelled by all vehicles after slowing down is less than the distance of the vehicles from the pedestrians, then CL is red and PL is green, and the traffic lights return to the default state after the pedestrians have passed quickly and the vehicles speed up to pass, with an animated demonstration.

4.3 If all vehicles pass at the original speed and the distance from the vehicle to the pedestrian is less, then CL is yellow to alert the driver that someone is passing and prevent the driver from accelerating and PL is green to allow the pedestrian to pass and an animation is shown. Like figure 2.
 Conclusion
The overall project has been completed and, in this project, has done the internet connection, tried speed measurement on passing vehicles, animated the real time situation through MATLAB, as well as will have completed the traffic. However, the production of the project has also revealed problems in the project and the way forward.

Hardware issues.
1. the Raspberry Pi should not be used, as this is the first time to use the Raspberry Pi resulting in insufficient understanding of its positioning and characteristics, the Raspberry Pi does not have an analogue interface resulting in a large number of errors in the data obtained from the infrared; the single-threaded mode of operation makes programming more difficult.
2.According to the background of the design, the main purpose is to reduce problematic traffic accidents in the road and to facilitate pedestrians who are physically unchanged, but because the road is long it is not possible to detect pedestrians on the whole road and there may still be various problematic possibilities.
3.The project is designed for 400 meters between the vehicle and the junction. However, if there are bends in the road or reduced visibility due to bad weather, drivers will not be able to see the signals in time to operate the system, which will render it useless.

Software issues.
1. The combination of animation and sensors is not perfect, which results in a certain delay in the demonstration, and if this delay accumulates to a certain amount it will be impossible to demonstrate effectively.
2. The design conditions are too ideal and the fault tolerance is too lows

