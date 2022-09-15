%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%What the script does:

%This script allows the user to communicate with an Aligent Multimeter and
%WEISS WKL34 (Thermal Chamber). These two devices are used to measure the 
%resistance throughout while controling the temperature and humidity
% of the thermal chamber.
%1. The user defines the set of humidity points
%2. A cycle will run to achive the starting set point
%3. Once there, for each Temperature/Humidity Point, a command will be sent to 
%   the climate chamber and that condition will be hold for 1 minute

%The code will return the following files in a folder named by the user: 
%.txt, .mat and .png.
%The final returned plot shows the resistance variation with the variation
%of the humidity.


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Clear vars and innitialize variables
try
    s=instrfind;
    delete(instrfindall);
    fclose(s);
    delete(s);
    clear s;
    catch exeption
end

clear all
close all
count = 0; %Contador de posições

%%%%%%%%%%%%% CREATE NEW OBJECTS AND FILE PATHS AND FORMAT %%%%%%%%%%%%%%%%

Sensor = input('Sensor Label: ','s');
filename = strcat(Sensor, '\results.txt');
mkdir(Sensor);

newobjs = instrfind;

if isempty(newobjs) == 0
fclose(newobjs);
delete(newobjs);
clear newobjs
end

%%%%%%%%%%% OBTAIN I/O WITH myDmm AND DEVICE CONFIGURATION %%%%%%%%%%%%%%%%

myDmm = visa('AGILENT', 'USB0::0x0957::0x0607::MY53001804::0::INSTR');
%Configure Visa Object and define used multimeter 

myDmm.InputBufferSize = 50000; %BUFFER SIZE BY DEFECT IS 32
myDmm.Timeout = 120;

%%%%%%%%%%%%%%% CONFIGURE MEASUREMENT OF MULTIMETER %%%%%%%%%%%%%%%%%

fopen(myDmm); 
set(myDmm, 'EOSMode','read&write');
set(myDmm, 'EOSCharCode','LF'); 
fprintf(myDmm, '*CLS;*RST');

idn = query(myDmm, '*IDN?');
disp(['IDN? = ' idn(1:end-1)]);

fprintf(myDmm, 'CONF:RES:RANG:AUTO 1');

%%%%%%%%%%%%%%% CONFIGURE CLIMATE CHAMBER %%%%%%%%%%%%%%%%%
%% COM parameters
%Define serial port
COM = 'COM4';
s=serial(COM);
set(s,'Timeout',5,'BaudRate',9600,'Parity','none');
fopen(s);

%% Read Atual Status
% The humidity once a value is sent usually starts at a high value
disp(['Actual temperature: ',num2str(ReadTemp(s)), ' °C'])
disp(['Actual Humidity: ', num2str(ReadHum(s)), '% r.h'])


%%Send Temperature and humidity wanted
Pos=1;
HumHoldValues=[30:2:97];
TempHoldValues=25*ones(size(HumHoldValues,2));
HoldTime=3*60;
Cont_Hum=HumHoldValues(Pos);
Cont_Temp=TempHoldValues(Pos);
SendTempHum(s,Cont_Temp,Cont_Hum)

%%%%%%%%%%%%%%%%%%%% LIVE-PLOT Adjusting to initial values %%%%%%%%%%%%%%%%%%%%%%%%%%%%
%The humidity always starts at a high value
%A first run is set to arrive to the desired initial setpoints
%The idea is that the sensor is not in the chamber

Values_startHum = [];
Values_startTemp = [];
Values_startTime = [];

im = figure;

tic
while(ReadHum(s) ~= Cont_Hum)
    count = count + 1;
    Values_startHum(count)= ReadHum(s);
    Values_startTemp(count)= ReadTemp(s);
    Values_startTime(count)= toc;
    %plot(Values_startTime, Values_startHum);
    [hAx,hLine1,hLine2] = plotyy(Values_startTime,Values_startHum,Values_startTime,Values_startTemp) 
    xlabel('Time (s)');
    ylabel(hAx(1),'Humidity (%% r.h)') % left y-axis 
    ylabel(hAx(2),'Temperature') % right y-axis
    ylim([0 100])
    drawnow;
end

disp('Arrived to starting position')
clearvars Values_startHum Values_startTemp Values_startTime

%%%%%%%%% CREATING VECTORS WHERE IT WILL SAVE THE READ VALUES %%%%%%%%%%%%
ValuesR = [];
ValuesT = [];
ValuesH =[];
%ValuesTheorical = [];
count = 0; %Contador de posições

%%%%%%%%%%%%%%%%%%%% LIVE-PLOT Humidity vs Resistance %%%%%%%%%%%%%%%%%%%%%%%%%%%%
fileID = fopen(filename, 'wt');
fprintf(fileID, 'Humidity (%% r.h), Resistance (Ohm) \n');

im = figure;
an = animatedline();

ylabel('Resistance (Ohm)');
xlabel('Humdity (%% r.h)');
title(Sensor);
subtitle('Resistance Variation with Humidity');

%%%%%%%%%%%%%%%%%%%%%%% DATA ACQUISITION %%%%%%%%%%%%%%%%%%%%%%%%%%% 

%Parent cicle ensures that all the Humidity points are swept
while(ReadHum(s) <= HumHoldValues(end))
    
    % Feedback if the set point is achieved
    % Collects data until the current set point
    while(ReadHum(s) < HumHoldValues(HumPos) & ReadTemp(s) = TempHoldValues(Humpos))
        count = count+1;
        drawnow;
        %CONFIGURED TO MEASURE RESISTANCE
        a = str2num(query(myDmm, 'MEAS:RES?'));
        ValuesR(count) =  str2num(query(myDmm, 'MEAS:RES?'));
        ValuesT(count) = ReadTemp(s);
        ValueH(count)= ReadHum(s);
    
        pause(10);
       
        %fprintf(fileID, '%f, %f \n', ValuesR(count), ValuesT(count));
        fprintf(fileID, '%f, %f \n', ValuesH(count), ValuesR(count));

        %if(ReadTemp(s) >= TempHoldValues(35))
        if ~ishandle(im)
            % Stop the if cancel button was pressed
            disp('Stopped by user');
            StopChamber(s);
            break;
        else
            % Update the wait bar
            addpoints(an,ValuesH(count), ValuesR(count));
        end  
    end
    
    tic %Initialize Timer
    
    %Holding one of the Humidity/Temperature values in the chamber
    while (toc < HoldTime) 
        
        %SE CALHAR PARAR A CAMARA NAO SERIA MA IDEIA E MANDAR A NOVA
        %TEMPERATURA DEPOIS DO TOC ATIVA A CAMARA, TESTAR
        %StopChamber(s)
        count = count+1;
        drawnow;
        %a = str2num(query(myDmm, 'MEAS:RES?'));
        ValuesR(count) =  str2num(query(myDmm, 'MEAS:RES?'));
        ValuesT(count) = ReadTemp(s);
        ValuesH(count) = ReadHum(s);

        pause(10)

        fprintf(fileID, '%f, %f \n', ValuesT(count), ValuesH(count));
        
    end
    
    if(HumPos < size(HumHoldValues,2)) %Maximum position set
        HumPos = HumPos+1;
        Cont_Hum  = HumHoldValues(HumPos);
        Cont_Temp = TempHoldValues(HumPos);
        %SendTemp(s,Cont_Hum)
        SendTempHum(s,Cont_Temp,Cont_Hum)
    end
    
end

% %%%%%%%%%%%%%%%%%%%%%% DATA TREAMENT AND PLOT %%%%%%%%%%%%%%%%%%%%%%%%%%

im = figure;


hold on;
plot(ValuesH, ValuesR);

xlabel('Humidity (% r.h)');
ylabel('Resistante (\Omega)');

%legend('Theorical Values', 'Experimental Values');
title(Sensor);
subtitle('Resistance Variation whith humidity');

drawnow
save( strcat(Sensor, '\Vars'), 'ValuesH', 'ValuesR');
saveas(im, strcat(Sensor, '\plot.png'));



%%%%%%%%%%%%%%%%%%%%%%%% CLOSE AND DELETE OBJECTS %%%%%%%%%%%%%%%%%%%%%%%%%


%% Stop Chamber
StopChamber(s)

fclose(s);
delete(s);
clear s;
