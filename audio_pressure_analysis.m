set(0,'DefaultFigureWindowStyle','docked')

function audio_pressure_analysis
path='G:\My Drive\Postdoc with Dorgan\Gait Change Project\DAQ_Acquisition\_Raw data\';
sensor_file='08-10-2021 17-36.mat';
load([path filesep sensor_file]);

sensor_num=data.Dev3_ai6;
sample_freq=1000;
filename = 'test';
filetype = '.wav';
audiowrite([path filename filetype],sensor_num,sample_freq);

[audio,fs] = audioread([path filename filetype]);

%% View Strips
tmp = time2num(data.Time(end)/10);
figure
strips(audio,tmp,sample_freq)
title('Ten equilength strips of pressure data')

clear tmp

%% Way better way to plot all the sensors

figure;
stackedplot(data)

%% Plot power analysis

%of a single sensor
figure
subplot(2,1,1)
t = linspace(0,size(audio,1)/fs,size(audio,1));
plot(t,audio)
ylabel('Amplitude')

subplot(2,1,2)
pspectrum(audio);


%of a every sensor
figure
subplot(2,1,1)
plot(data.Time,data.Dev3_ai0)
hold on
plot(data.Time,data.Dev3_ai1)
plot(data.Time,data.Dev3_ai2)
plot(data.Time,data.Dev3_ai3)
plot(data.Time,data.Dev3_ai4)
plot(data.Time,data.Dev3_ai5)
plot(data.Time,data.Dev3_ai6)
plot(data.Time,data.Dev3_ai7)
ylabel('Amplitude')

subplot(2,1,2)
pspectrum(data)
legend('Sensor1','Sensor2','Sensor3','Sensor4','Sensor5','Sensor6','Sensor7','Sensor8')

%% Plot Frequency in the Time Domain

%First with a spectrogram
figure
subplot(2,1,1)
t = linspace(0,size(audio,1)/fs,size(audio,1));
plot(t,audio)
ylabel('Amplitude')

subplot(2,1,2)
pspectrum(audio,'spectrogram','MinThreshold',-100);
xlabel('Time (s)')

%Then with a scalogram
figure
subplot(2,1,1)
t = linspace(0,size(audio,1)/fs,size(audio,1));
plot(t,audio)
ylabel('Amplitude')

subplot(2,1,2)
cwt(audio,sample_freq)%This function breaks matlab????
xlabel('Time (s)')
caxis([-100 20])

%% Using cross-correlation to find a time delay between one set of sensors
testDelay=finddelay(data.Dev3_ai0,data.Dev3_ai3);
seconds(testDelay*(1/sample_freq))

%plot the xcorr
[c,lags]=xcorr(data.Dev3_ai0,data.Dev3_ai3);

figure
stem(lags,c)


%% Centroid
%centroid finds areas where the range of the amplitude increases dramatically
centroid = spectralCentroid(audio,fs); 

figure
subplot(2,1,1)
t = linspace(0,size(audio,1)/fs,size(audio,1));
plot(t,audio)
ylabel('Amplitude')

subplot(2,1,2)
t = linspace(0,size(audio,1)/fs,size(centroid,1));
plot(t,centroid)
xlabel('Time (s)')
ylabel('Centroid (Hz)')

%% Spread
% spread is the standard deviation around the centroid
spread = spectralSpread(audio,sample_freq);

figure
subplot(2,1,1)
spectrogram(audio,round(sample_freq*0.05),round(sample_freq*0.04),2048,sample_freq,'yaxis')

subplot(2,1,2)
t = linspace(0,size(audio,1)/sample_freq,size(spread,1));
plot(t,spread)
xlabel('Time (s)')
ylabel('Spread')

%% skewness
%skewness measure symmetry around the centroid

skewness = spectralSkewness(audio,sample_freq);
t = linspace(0,size(audio,1)/sample_freq,size(skewness,1))/60;

figure
subplot(2,1,1)
spectrogram(audio,round(sample_freq*0.05),round(sample_freq*0.04),round(sample_freq*0.05),sample_freq,'yaxis','power')
view([-58 33])

subplot(2,1,2)
plot(t,skewness)
xlabel('Time (minutes)')
ylabel('Skewness')

%% Kurtosis
%measures the peakiness of the signal or how peaky (less flat) it is

kurtosis = spectralKurtosis(audio,sample_freq);

figure
t = linspace(0,size(audio,1)/sample_freq,size(audio,1));
subplot(2,1,1)
plot(t,audio)
ylabel('Amplitude')

t = linspace(0,size(audio,1)/sample_freq,size(kurtosis,1));
subplot(2,1,2)
plot(t,kurtosis)
xlabel('Time (s)')
ylabel('Kurtosis')

%% Entropy TODO COMPARE THE HISTOGRAMS OF BEHAVIOR VS EMPTY TRACES
%measure of disorder

entropy = spectralEntropy(audio,sample_freq);

figure
t = linspace(0,size(audio,1)/sample_freq,size(audio,1));
subplot(3,1,1)
plot(t,audio)
ylabel('Amplitude')

t = linspace(0,size(audio,1)/sample_freq,size(entropy,1));
subplot(3,1,2)
plot(t,entropy)
xlabel('Time (s)')
ylabel('Entropy')

subplot(3,1,3)
h1 = histogram(entropy);

%% Flatness 
%more flatness, means less signal

flatness = spectralFlatness(audio,sample_freq);

figure
subplot(2,1,1)
t = linspace(0,size(audio,1)/sample_freq,size(audio,1));
plot(t,audio)
ylabel('Amplitude')

subplot(2,1,2)
t = linspace(0,size(audio,1)/sample_freq,size(flatness,1));
plot(t,flatness)
ylabel('Flatness')
xlabel('Time (s)')

%% Crest
%higher crest = higher signal:noise ratio

crest = spectralCrest(audio,sample_freq);

figure
subplot(2,1,1)
t = linspace(0,size(audio,1)/sample_freq,size(audio,1));
plot(t,audio)
ylabel('Amplitude')

subplot(2,1,2)
t = linspace(0,size(audio,1)/sample_freq,size(crest,1));
plot(t,crest)
ylabel('Crest')
xlabel('Time (s)')

%% Flux
%measures difference in signal over time

flux = spectralFlux(audio,sample_freq);

figure
subplot(2,1,1)
t = linspace(0,size(audio,1)/sample_freq,size(audio,1));
plot(t,audio)
ylabel('Amplitude')

subplot(2,1,2)
t = linspace(0,size(audio,1)/sample_freq,size(flux,1));
plot(t,flux)
ylabel('Flux')
xlabel('Time (s)')

%% Slope
%measures the amount of decrease in the spectrum
%useful in voice discrimination

figure
subplot(3,1,1)
t = linspace(0,size(audio,1)/fs,size(audio,1));
plot(t,audio)
ylabel('Amplitude')

subplot(2,1,2)
slope = spectralSlope(audio,sample_freq);
t = linspace(0,size(audio,1)/sample_freq,size(slope,1));
subplot(3,1,2)
spectrogram(audio,round(sample_freq*0.05),round(sample_freq*0.04),round(sample_freq*0.05),sample_freq,'yaxis','power')

subplot(3,1,3)
plot(t,slope)
ylabel('Slope')
xlabel('Time (s)')

%% Spectral Decrease
% emphasizes slopes of lower frequencies
%useful in musical instrument recognition

decrease = spectralDecrease(audio,sample_freq);


t1 = linspace(0,size(audio,1)/sample_freq,size(decrease,1));

figure
subplot(2,1,1)
t = linspace(0,size(audio,1)/fs,size(audio,1));
plot(t,audio)
ylabel('Amplitude')

subplot(2,1,2)
plot(t1,decrease)
ylabel('Decrease')


%% Rolloff Point
%determines the bandwidth of the audio signal

r1 = spectralRolloffPoint(audio,sample_freq);

t1 = linspace(0,size(audio,1)/sample_freq,size(r1,1));

figure
subplot(2,1,1)
t = linspace(0,size(audio,1)/fs,size(audio,1));
plot(t,audio)
ylabel('Amplitude')

subplot(2,1,2)
plot(t1,r1)
ylabel('Rolloff Point (Hz)')
xlabel('Time (s)')

end