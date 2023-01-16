%% THIS PROGRAM IS A WORK IN PROGRESS. PARTS MAY NOT YET WORK. BE YE WARNED.
%% Logistics
set(0,'DefaultFigureWindowStyle','docked')

vidPath = 'G:\My Drive\Ant Farm Experiments\Video Data Files';
pressPath = 'G:\My Drive\Ant Farm Experiments\Pressure Data Files';
photoPath = 'G:\My Drive\Ant Farm Experiments\Worm Photos (with ruler)';
savePath = 'G:\My Drive\Ant Farm Experiments\Matlab Files';

force_image_reeval=0; %set this to one if you want to reanalyse existing videos

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

%% Load video file and video notes
flnm=experiment_notes.VideoFileName{exp_row,:};
vidname = flnm;
vidtype = '.MOV';
notetype = '.csv';

vid=VideoReader([vidPath filesep vidname vidtype]);
vidnote=readtable([vidPath filesep vidname notetype]);

for i = 1:height(vidnote)
    if length(vidnote.View{i})<4
        if vidnote.View{i} == 'Top'
            vidnote.View{i}='Top ';
        else error (['Row ' num2str(i) ' of the video notes says ' vidnote.View{i} ' which is unrecognized.'])
        end
    end
end
clear flnm vidname vidtype notetype

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
best_behavior = str2num(str2mat(experiment_notes.WhenIsTheBestVisibleBehaviorSegment__secs_Secs__videoTime_{exp_row,:}));
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
    patch([best_behavior(1),best_behavior(1) best_behavior(2),best_behavior(2)],[y(1),y(2),y(2),y(1)],'y','FaceAlpha',0.3,'EdgeColor','y')
%     patch([second_behavior(1),second_behavior(1) second_behavior(2),second_behavior(2)],[y(1),y(2),y(2),y(1)],'y','FaceAlpha',0.5,'EdgeColor','y')
%     patch([third_behavior(1),third_behavior(1) third_behavior(2),third_behavior(2)],[y(1),y(2),y(2),y(1)],'y','FaceAlpha',0.5,'EdgeColor','y')
behavior_annotation(vidnote)
end
xlabel('Time (s)')
subplot(length(sensors),1,1)
title('Full pressure trace')
customlegend1


clear i y pdata

burrow_trace=figure;
for i=1:length(sensors)
    j=1:2:2*length(sensors);
    subplot(length(sensors),2,j(i))
    pdata=data.Properties.VariableNames{sensors(i)+1};
    plot(data.Time(burrow_start*1000:best_behavior(2)*1000),data{burrow_start*1000:best_behavior(2)*1000,i+1})
    subtitle(['Pressure sensor #' num2str(sensors(i))])
    ylabel('Pressure in Voltage')
    axis tight
    y=ylim;
    patch([best_behavior(1),best_behavior(1) best_behavior(2),best_behavior(2)],[y(1),y(2),y(2),y(1)],'y','FaceAlpha',0.3,'EdgeColor','y')
%     patch([second_behavior(1),second_behavior(1) second_behavior(2),second_behavior(2)],[y(1),y(2),y(2),y(1)],'y','FaceAlpha',0.5,'EdgeColor','y')
%     patch([third_behavior(1),third_behavior(1) third_behavior(2),third_behavior(2)],[y(1),y(2),y(2),y(1)],'y','FaceAlpha',0.5,'EdgeColor','y')
% 
behavior_annotation(vidnote)

end
xlabel('Time (s)')
subplot(length(sensors),2,1)
title('Burrowing pressure trace')
customlegend1

clear i y pdata j

%% Look at video data
burrow_start_v=experiment_notes.WhenDidBurrowingStart__secsVideoTime_(exp_row,:);
numFrame = vid.NumFrames;
%Video is 60fps

if best_behavior(2)*60 <= numFrame
    end_behavior = best_behavior(2)*60;
else
    end_behavior = numFrame;
end

videoframe=figure;
subplot(1,2,1)
imshow(vid.read(best_behavior(1)*60))
subplot(1,2,2)
imshow(vid.read(end_behavior))

bName = questdlg('Does the camera appear steady?','Check stability','Yes', 'No ','Yes');

if bName == 'No '
    error 'Camera moved during the requested segment. Change the time bounds for the video.'
end

close(videoframe)

%% Run through video analysis

se = strel('disk',2,8);
frames = round(linspace(best_behavior(1)*60,end_behavior,(end_behavior-best_behavior(1)*60)/100)); 

if exist([savePath filesep experiment_notes.PressureDataFilename{exp_row} filesep '1 Image Differences']) == 0 || force_image_reeval==1
mkdir([savePath filesep experiment_notes.PressureDataFilename{exp_row} filesep '1 Image Differences']);
mkdir([savePath filesep experiment_notes.PressureDataFilename{exp_row} filesep '2 Thresholded Images']);
mkdir([savePath filesep experiment_notes.PressureDataFilename{exp_row} filesep '3 Skeletons']);


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
imshow(vid.read(best_behavior(1)*60))
title('Beginning of behavior')

subplot(2,4,4)
imshow(vid.read(end_behavior))
title('End of behavior')

subplot(2,2,4)
imshow(vid.read(best_behavior(1)*60))
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
 

%% Interactively pull distance from calibration video
Caltime=experiment_notes.WhenCanTheRulerBeSeenInTheCalibrationVideo__secs_(exp_row,:)*60;
calfig=figure;
imshow(Calvid.read(Caltime))
title(['Choose ruler points'])

%Give instructions to person finding the distance
bName = questdlg('Make a line with the largest length of visible ruler. Then press enter.','Instructions','Ok','Ok');
       
% Interactively find the length
h = drawline;
wait(h);

% Store ROI points
tmp = h.Position;
cal.x = tmp(:,1);
cal.y = tmp(:,2);

% Show ROI points
delete(h)
hold on
plot(cal.x,cal.y,'r-')
pause(1)
hold off

%Do math to find the length in pixels TODO
pixel_length=sqrt((cal.x(2)-cal.x(1))^2+(cal.y(2)-cal.y(1))^2);

%Ask user how many cm that line represents
prompt = {'How many cm long is this line?'};
dlgtitle = 'Ruler length';
dims = [1 35];
definput = {''};
cm = inputdlg(prompt,dlgtitle,dims,definput);

%Find how many pixels per cm
calibration=pixel_length/str2num(cm{1}); %pix/cm

close(calfig)

%% Add scale bar to video heatmap
figure(burrow_trace)
hold on
line([60 60+(2*calibration)],[1000 1000],'Color','k')
text(60,950,'2 cm')

%% Analyse pressure as audio

%% Functions

function behavior_annotation (vidnote)
%adds the behavior annotation lines to the pressure graph based on the
%behaviors laid out in the csv file video notes
for j=1:height(vidnote)
    x=vidnote.CameraTime_s_(j);
    l=mean(ylim)+0.5*std(ylim);
    text(x,l,vidnote.ID(j))
    if vidnote.View{j} == 'Top '
        lnstyle='--';
    else
        lnstyle='-';
    end
    if vidnote.ID{j} == 'B' || vidnote.ID{j} == 'A'
        color=[0.6350 0.0780 0.1840];
    elseif vidnote.ID{j} == 'P' || vidnote.ID{j} == 'F' || vidnote.ID{j} == 'E'
        color=[0.4660 0.6740 0.1880];
    else
        color='black';
    end
    patch([x,x],ylim,'w','EdgeColor',color,'LineStyle',lnstyle)
    hold on
end

    
end


function customlegend1
%Creates a custom legend for the behavior annotation lines on the pressure graphs.
hold on
tmp{1} = plot(nan,'Color',[0.4660 0.6740 0.1880]);%for P or F
tmp{2} = plot(nan,'Color',[0.6350 0.0780 0.1840]);%for B or A
tmp{3} = plot(nan,'Color','black','LineStyle','--');%for Top view
tmp{4} = plot(nan,'Color','black','LineStyle','-');%for Side view
tmp{5} = patch([nan],[nan],'y','FaceAlpha',0.3,'EdgeColor','y');

legend([tmp{:}],{'Forward','Backward','Top View','Side View','Visible segment'})
end

