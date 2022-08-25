
%% Logistics
set(0,'DefaultFigureWindowStyle','docked')

vidPath = 'G:\My Drive\Ant Farm Experiments\Video Data Files';
pressPath = 'G:\My Drive\Ant Farm Experiments\Pressure Data Files';
photoPath = 'G:\My Drive\Ant Farm Experiments\Worm Photos (with ruler)';
savePath = 'G:\My Drive\Ant Farm Experiments\Matlab Files';

%% Read Google Sheet Data
ID = '1f4FSCvsedKow69VxGdcVAF0-ALxNHTTJMh532JSbPfw';
sheet_name = 'Experiment Notes';
url_name = sprintf('https://docs.google.com/spreadsheets/d/%s/gviz/tq?tqx=out:csv&sheet=%s',...
    ID, sheet_name);
experiment_notes = webread(url_name);

clear ID sheet_name url_name

%% Interactively choose experiment to analyze
list=experiment_notes.Date_mm_dd_yy_;
[indx,tf] = listdlg('PromptString','Choose the experiment date to analyze.','ListSTring',list,'SelectionMode','single')
date=list(indx);
if length(find(experiment_notes.Date_mm_dd_yy_ == datestr(date)))>1
    poss_dates_indexes=find(experiment_notes.Date_mm_dd_yy_ == datestr(date));
    times=experiment_notes.Time_hh_mm_(poss_dates_indexes);
    [indx,tf] = listdlg('PromptString','Which experiment on that day would you like to analyze?','ListSTring',times,'SelectionMode','single')
    exp_row=poss_dates_indexes(indx);
else
    exp_row=indx;
end

clear indx date poss_dates_indexes times tf

%% Check if worm burrowed
if experiment_notes.DidTheWormBurrowDuringThisTrial_{exp_row,:} == 'N'
    error 'Worm did not burrow during this trial'
end

%% Load pressure file
flnm=experiment_notes.PressureDataFilename{exp_row,:};
pressname = flnm;
presstype = '.mat';
load([pressPath filesep pressname presstype]); %this loads 'data'
data=timetable2table(data);

clear flnm pressname presstype

%% Load video file
flnm=experiment_notes.VideoFileName{exp_row,:};
vidname = flnm;
vidtype = '.MOV';

vid=VideoReader([vidPath filesep vidname vidtype]);

clear flnm vidname vidtype

%% Load calibration video
flnm=experiment_notes.CalibrationFileName{exp_row,:};
if ~isnan(flnm)
    vidname = flnm;
    vidtype = '.MOV';
    
    Calvid=VideoReader([vidPath filesep vidname vidtype]);
    
else
    warning 'No calibration video available'
end
clear flnm vidname vidtype

%% Load worm photo
flnm=experiment_notes.WormPhotoFileName{exp_row,:};
if ~isnan(flnm)
    photoname = flnm;
    
    wormim=imread([photoPath filesep photoname]);
    
else
    warning 'No worm photo available'
end
clear flnm photoname phototype

%% Determine which sensors were used
sensors=str2num(experiment_notes.sensorsUsed_topToBottom_{exp_row,:});

%% Plot pressure data
burrow_start=experiment_notes.WhenDidBurrowingStart__secsVideoTime_(exp_row,:)-experiment_notes.HowManySecondsIntoTheVideoDidMatlabStartRecording_(exp_row);
first_behavior = str2num(str2mat(experiment_notes.WhenIsTheFirstVisibleBehavior__secs_Secs__videoTime_{exp_row,:}));
% second_behavior = str2num(str2mat(experiment_notes.WhenIsTheSecondVisibleBehavior__secs_Secs__videoTime_(exp_row,:)));
% third_behavior = str2num(str2mat(experiment_notes.WhenIsTheThirdVisibleBehavior__secs_Secs__videoTime_(exp_row,:)));


full_trace=figure;

for i=1:length(sensors)
    subplot(length(sensors),1,i)
    pdata=data.Properties.VariableNames{sensors(i)+1};
    plot(data.Time(100:end),data{100:end,i+1})
    subtitle(['Pressure sensor #' num2str(sensors(i))])
    ylabel('Pressure in Voltage')
    axis tight
    y=ylim;
    patch([burrow_start,burrow_start],ylim,'r','EdgeColor','r')
    patch([first_behavior(1),first_behavior(1) first_behavior(2),first_behavior(2)],[y(1),y(2),y(2),y(1)],'y','FaceAlpha',0.5,'EdgeColor','y')
%     patch([second_behavior(1),second_behavior(1) second_behavior(2),second_behavior(2)],[y(1),y(2),y(2),y(1)],'y','FaceAlpha',0.5,'EdgeColor','y')
%     patch([third_behavior(1),third_behavior(1) third_behavior(2),third_behavior(2)],[y(1),y(2),y(2),y(1)],'y','FaceAlpha',0.5,'EdgeColor','y')
% 
end
xlabel('Time (s)')
subplot(length(sensors),1,1)
title('Full pressure trace')

clear i y pdata

burrow_trace=figure;
for i=1:length(sensors)
    j=1:2:2*length(sensors);
    subplot(length(sensors),2,j(i))
    pdata=data.Properties.VariableNames{sensors(i)+1};
    plot(data.Time(burrow_start*1000:end),data{burrow_start*1000:end,i+1})
    subtitle(['Pressure sensor #' num2str(sensors(i))])
    ylabel('Pressure in Voltage')
    axis tight
    y=ylim;
    patch([first_behavior(1),first_behavior(1) first_behavior(2),first_behavior(2)],[y(1),y(2),y(2),y(1)],'y','FaceAlpha',0.5,'EdgeColor','y')
%     patch([second_behavior(1),second_behavior(1) second_behavior(2),second_behavior(2)],[y(1),y(2),y(2),y(1)],'y','FaceAlpha',0.5,'EdgeColor','y')
%     patch([third_behavior(1),third_behavior(1) third_behavior(2),third_behavior(2)],[y(1),y(2),y(2),y(1)],'y','FaceAlpha',0.5,'EdgeColor','y')
% 
end
xlabel('Time (s)')
subplot(length(sensors),2,1)
title('Burrowing pressure trace')

clear i y pdata j


%% Look at video data
burrow_start_v=experiment_notes.WhenDidBurrowingStart__secsVideoTime_(exp_row,:);
numFrame = vid.NumFrames;
%Video is 60fps

if first_behavior(2)*60 <= numFrame
    end_behavior = first_behavior(2)*60;
else
    end_behavior = numFrame;
end

videoframe=figure;
subplot(1,2,1)
imshow(vid.read(first_behavior(1)*60))
subplot(1,2,2)
imshow(vid.read(end_behavior))

bName = questdlg('Does the camera appear steady?','Check stability','Yes', 'No ','Yes');

if bName == 'No '
    error 'Camera moved during the requested segment. Change the time bounds for the video.'
end

close(videoframe)
%% Run through video analysis
mkdir([savePath filesep experiment_notes.PressureDataFilename{exp_row} filesep '1 Image Differences']);
mkdir([savePath filesep experiment_notes.PressureDataFilename{exp_row} filesep '2 Thresholded Images']);
mkdir([savePath filesep experiment_notes.PressureDataFilename{exp_row} filesep '3 Skeletons']);

se = strel('disk',2,8);
frames = round(linspace(first_behavior(1)*60,end_behavior,(end_behavior-first_behavior(1)*60)/100)); 
a = vid.read(frames(1));
for i =1:length(frames)-1
   
    b = vid.read(frames(i+1));
    c = imabsdiff(a,b); %take the difference between this frame and the previous one
    d = imadjust(rgb2gray(c)); %make the result grayscale and adjust the contrast to use the full range from 0-1
    e = im2bw(d,0.95); %thresholds the image and makes it black and white
    a = b;
    e=imerode(e,se);
    f = bwskel(e);
    
    [y_points,x_points] = find(e);
    
    epoints = [x_points,y_points];
    
    save([savePath filesep experiment_notes.PressureDataFilename{exp_row} filesep '2 Thresholded Images' filesep 'Frame' num2str(i)], 'epoints');
    
    imwrite(c,[savePath filesep experiment_notes.PressureDataFilename{exp_row} filesep '1 Image Differences' filesep 'Frame' num2str(i) '.png']);
    imwrite(c,[savePath filesep experiment_notes.PressureDataFilename{exp_row} filesep '2 Thresholded Images' filesep 'Frame' num2str(i) '.png']);
    imwrite(c,[savePath filesep experiment_notes.PressureDataFilename{exp_row} filesep '3 Skeletons' filesep 'Frame' num2str(i) '.png']);

end

%% Create the color gradient for the video analysis figure

c1 = [1 0 0]; %rgb value for the starting color
c2 = [0 0 1]; %rgb value for the ending color

%Creates a value determining the amount of color change between each frame
cr=(c2(1)-c1(1))/(length(frames)-1);
cg=(c2(2)-c1(2))/(length(frames)-1);
cb=(c2(3)-c1(3))/(length(frames)-1);

%Initializes matrices.
gradient=zeros(length(frames),3);
r=zeros(10,length(frames));
g=zeros(10,length(frames));
b=zeros(10,length(frames));
%for each color step, increase/reduce the value of Intensity data.
for j=1:length(frames)
    gradient(j,1)=c1(1)+cr*(j-1);
    gradient(j,2)=c1(2)+cg*(j-1);
    gradient(j,3)=c1(3)+cb*(j-1);
    r(:,j)=gradient(j,1);
    g(:,j)=gradient(j,2);
    b(:,j)=gradient(j,3);
end

%merge R G B matrix and obtain our image.
imColGradient=cat(3,r,g,b);

%% Create TickLabels for video analysis figure
ColTicks= linspace(frames(1),frames(end),6);
ColTicks=ColTicks/3600;
ColTicks = round(ColTicks,2,'significant')
TickLabels = {
    [num2str(ColTicks(1)), ' min'];
    [num2str(ColTicks(2)), ' min'];
    [num2str(ColTicks(3)), ' min'];
    [num2str(ColTicks(4)), ' min'];
    [num2str(ColTicks(5)), ' min'];
    [num2str(ColTicks(6)), ' min'];
   }

%% Show finished video analysis next to pressure trace of burrow
figure(burrow_trace)

subplot(2,4,3)
imshow(vid.read(first_behavior(1)*60))
title('Beginning of behavior')

subplot(2,4,4)
imshow(vid.read(end_behavior))
title('End of behavior')

subplot(2,2,4)
imshow(vid.read(first_behavior(1)*60))
hold on
set(gca, 'YDir','reverse')
for i = 1:(length(frames)-1)
    load([savePath filesep experiment_notes.PressureDataFilename{exp_row} filesep '2 Thresholded Images' filesep 'Frame' num2str(i)]);
    hold on
    plot(epoints(:,1),epoints(:,2),'.','MarkerFaceColor',gradient(i,:),'MarkerEdgeColor',gradient(i,:))
end

colormap(gradient)
ColBar=colorbar;
ColBar.Ticks = [0,0.2,0.4,0.6,0.8,1];
ColBar.TickLabels = TickLabels;
title('Heatmap of changes over time between beginning and ending of behavior')
 
pause





%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% s=50;%smoothing parameter
% 
% figure
% subplot(3,1,1)
% implay('C:\Users\amckee\Desktop\Matlab Practice\DSC_0007.mov')
% 
% %Raw Data - in voltages, not pascals
% 
% %Sensor 1
% sdata.Sensor1 = smoothdata(data.Dev3_ai0,'gaussian',s);
% 
% subplot(3,1,2)
% plot(data.Time,data.Dev3_ai0)
% hold on
% plot(data.Time,sdata.Sensor1)
% xlabel('Time (s)')
% ylabel('Pressure (voltage from sensors)')
% legend('Raw','Smoothed')
% title('Sensor 1')
% 
% %Sensor 2
% sdata.Sensor2 = smoothdata(data.Dev3_ai1,'gaussian',s);
% 
% subplot(3,1,3)
% plot(data.Time(5000:end),data.Dev3_ai1(5000:end))
% hold on
% plot(data.Time(5000:end),sdata.Sensor2(5000:end))
% xlabel('Time (s)')
% ylabel('Pressure (voltage from sensors)')
% legend('Raw','Smoothed')
% title('Sensor 2')
