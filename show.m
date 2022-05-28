clear all;
clc;

vpeople=1;% people speed m/s
s1=10;%Length of road m
s2=400;%Length of Sensors to traffic light m

r = raspi('192.168.187.98','pi','raspberry');

llG = 12;
llY = 13;
llR = 14;

ulG=15;
ulR=16;

configurePin(r, llG, 'DigitalOutput');
configurePin(r, llY, 'DigitalOutput');
configurePin(r, llR, 'DigitalOutput');

configurePin(r, ulG, 'DigitalOutput');
configurePin(r, ulR, 'DigitalOutput');

timemark=datetime('now');
cars = driving.scenario.Vehicle.empty;

scenario = drivingScenario('StopTime',10);
road(scenario,[0 -100; 0 100],'lanes',lanespec([1 1]));
road(scenario,[-10 0; 10 0],'lanes',lanespec([1 1]));

fig = figure;
set(fig,'Position',[0 0 600 400])
movegui(fig,'center')
hViewPnl = uipanel(fig,'Position',[0 0 1 1],'Title','Vehicle Spawn and Despawn');
hPlt = axes(hViewPnl);

plot(scenario,'Waypoints','on','Parent',hPlt)

waittime=[0,0.05,0];

while true
%     llight=0;%Green
%     ulight=2;%Red
    writeDigitalPin(r,llG,1);
    writeDigitalPin(r,llY,0);
    writeDigitalPin(r,llR,0);
    writeDigitalPin(r,ulG,0);
    writeDigitalPin(r,ulR,1);
    a=4;%Car deceleration m/s
    [data,timestamps]=thingSpeakRead(1666700,'Fields',[1,2,3],NumPoint=10,Readkey='PX6JCUNZQF1P8VDZ');
    disp(['car speed:',num2str(data(1,1)),' car length:',num2str(data(1,2)),'people:',num2str(data(1,3))])
    [n,m]=size(data);
    dt=0;
    time_place=find(timestamps>timemark);
    timemark=timestamps(end);
    cartime = datetime;
    for i=1:length(time_place)
        cartime(i)=timestamps(time_place(i));      
    end
    
    people_place=find(data(1:end,3)<0.4);
    if isempty(time_place)
        cartime=[];
    end
    %Determining valid data
    cound=[];
    dis=[];
    if m>0 && isempty(cartime)==false
        time = datetime('now');
        dt=time-cartime;
        dt=datevec(dt);
        [x,y]=size(dt);
        for i=1:x
            dis(i)=dt(i,6)*data(i,1);
        end
        cound=find(dis>0 & dis<s2);
    end 
 
    %No pedestrians passing 
    if isempty(people_place) && isempty(cound)==false
        %creat car
        cars = driving.scenario.Vehicle.empty;
        for i=1:length(cound)
            Car = vehicle(scenario,'EntryTime',dt(cound(i),6),'ExitTime',(dt(cound(i),6)+200/60));
            cars(end+1)=Car;
        end
        %First vehicle animation
        waypoints = [2,100;2,-100];
        speed = (60);
        for i=1:length(cars)
            path(cars(i),waypoints,speed)
        end
        restart(scenario)
        while advance(scenario)
            pause(0.001)
        end
        %Emptying the matrix
        clear cars;
        cound=[];
    end
    while isempty(people_place)==false
        tpu=(s1/vpeople)/2; %people Time required for a person to walk up to the halfway point
        if isempty(cound) %No car between man and sensor
            writeDigitalPin(r,llG,0);
            writeDigitalPin(r,llY,1);
            writeDigitalPin(r,llR,0);
            writeDigitalPin(r,ulG,1);
            writeDigitalPin(r,ulR,0);
%             llight = 1;%Yellow
%             ulight = 0;%Green
            people = actor(scenario,'ClassID',4,'EntryTime',0,'ExitTime',5,'Length',2,'Width',2,'Height',1.5);
            waypoints = [-10,2;10,2];
            speed = (4);
 
            trajectory(people,waypoints,speed)

            restart(scenario)
            while advance(scenario)
                pause(0.001)
            end
            %Emptying the matrix
            person=[];

                break;
            else
            disRam=zeros(length(cound));
            Scs=zeros(length(cound));
            Sca=zeros(length(cound));
            for i=1:length(cound)
                disRam(i)=s2-dis(cound(i));  %Distance of these vehicles to the traffic lights m
            end
             for i=1:length(cound)
                Scs(i)=data(cound(i),1)*tpu;  %The distance a car would travel if it maintained its original speed while a pedestrian was passing. m
             end
             for i=1:length(cound)
                Sca(i)=data(cound(i),1)*tpu-0.5*a*power((tpu-1),2);  %The distance a car will travel if it slows down evenly when a pedestrian passes.
             end
             if Sca>=disRam %
                 %llight = 0;%Green
                 %ulight = 2;%Red
                 writeDigitalPin(r,llG,1);
                 writeDigitalPin(r,llY,0);
                 writeDigitalPin(r,llR,0);
                 writeDigitalPin(r,ulG,0);
                 writeDigitalPin(r,ulR,1);
                 for i=1:length(cound)
                    Car = vehicle(scenario,'EntryTime',dt(cound(i),6),'ExitTime',(dt(cound(i),6)+200/60));
                    cars(end+1)=Car;
                end
                waypoints = [2,100;2,-100];
                speed = (60);
                for i=1:length(cars)
                    trajectory(cars(i),waypoints,speed)
                end
                people = actor(scenario,'EntryTime',0);

                waypoints1 = [-10,2;-7,2;10,2];
                speed1 = [4,0,4];
                waittime=[0;0.01;0];
                trajectory(people,waypoints1,speed1,waittime)

                restart(scenario)
                while advance(scenario)
                    pause(0.001)
                end
                %Emptying the matrix
                person=[];
                cars=[];
                cound=[];
                 break;
             else 
                 writeDigitalPin(r,llG,0);
                 writeDigitalPin(r,llY,0);
                 writeDigitalPin(r,llR,1);
                 writeDigitalPin(r,ulG,1);
                 writeDigitalPin(r,ulR,0);
                 cars = driving.scenario.Vehicle.empty;
                 for i=1:length(cound)
                    Car = vehicle(scenario,'EntryTime',dt(cound(i),6),'ExitTime',(dt(cound(i),6)+200/60));
                    cars(end+1)=Car;
                    pause(0.001)
                 end

                 waypoints = [2,100;2,7;2,-100];
                 speed = [60,0,60];
                 waittime=[0,1,0];
                 for i=1:length(cars)
                     path(cars(i),waypoints,speed,waittime)
                 end
                 people = actor(scenario,'ClassID',4,'EntryTime',0,'ExitTime',5,'Length',2,'Width',2,'Height',1.5);

                 waypoints1 = [-10,2;10,2];
                 speed1 = (4);
              
                 trajectory(people,waypoints1,speed1)
            
                 restart(scenario)
                 while advance(scenario)
                     pause(0.001)
                 end
                 %Emptying the matrix
                 cound=[];
%                  llight = 2;%Red
%                  ulight = 0;%Green
                 break;
             end
             if Scs<disRam
                 writeDigitalPin(r,llG,0);
                 writeDigitalPin(r,llY,1);
                 writeDigitalPin(r,llR,0);
                 writeDigitalPin(r,ulG,1);
                 writeDigitalPin(r,ulR,0);
                 for i=1:length(cound)
                    Car = vehicle(scenario,'EntryTime',dt(cound(i),6),'ExitTime',(dt(cound(i),6)+200/60));
                    cars(end+1)=Car;
                 end

                 waypoints = [2,100;2,-100];
                 speed = (50);
                 for i=1:length(cars)
                     path(cars(i),waypoints,speed)
                 end
                 people = action(scenario,'EntryTime',0);
                 person(end+1)=people;
                 waypoints1 = [-10,2;10,2];
                 speed1 = (4);
                 for i=1:length(person)
                     path(person(i),waypoints1,speed1)
                 end
                 restart(scenario)
                 while advance(scenario)
                     pause(0.001)
                 end
                 %Emptying the matrix
                 cars=[];
                 person=[];
                 cound=[];
%                  llight = 1;%Yellow
%                  ulight = 0;%Green
                  break; 
             end
        end
    end
%     pause(15);
%     thingSpeakWrite(1675633,'Fields',[1,2],'Values',{llight,ulight},'WriteKey','144CC0JMNXAESWQY')
    
end
