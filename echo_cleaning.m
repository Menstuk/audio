%% Parameters
fs = 16e3;
nBits = 16;
nChannels = 1; 
duration = 5;
echoTime = randi([0,2000],1,1) / 1000;
echoTime =0.100;
marginSamp = round(0.025 * fs);
newRec = 1;
display("The drawn echo is: " + string(echoTime) + " seconds");
%% Load the clean speech signal
if newRec
	recObj = audiorecorder(fs, nBits, nChannels);
	disp("Start Speaking");
	recordblocking(recObj, duration);
	disp("End of Recording");
	audioData = getaudiodata(recObj);
	soundsc(audioData,fs);
	
	% Apply the echo
	echoSamples = echoTime*fs;
	hEcho = zeros(1,echoSamples);
	hEcho(1) = 1; hEcho(echoSamples)=0.6;
	echoSig = filter(hEcho,1,audioData);
	soundsc(echoSig,fs)
end


%% Calculate the cepstrum
echoCep = echo_ceps_calc(echoSig,marginSamp); 
plot(echoCep); 


%% Find the periodicity in the cepstrum
[maxVal, maxInd] = max(echoCep);
timeSamp = maxInd + marginSamp;
echoEst = timeSamp/fs;
display("The estimated echo is: " + string(echoEst) + " seconds");

%% De-Echo with simple feedback scheme
padLen = timeSamp;
% padAudio = [zeros(timeSamp,1);audioData];
corrAudio = filter(1,[1 zeros(1,timeSamp-3) maxVal], echoSig);
corrAudio1 = corrAudio;
new_val = maxVal;
for i = 1:100
	last_val = new_val;
	echoCep = echo_ceps_calc(corrAudio,marginSamp);
	plot(echoCep);
	tmpMaxVal = echoCep(maxInd);
	if tmpMaxVal < maxVal/10
		break
	end
	error = tmpMaxVal - maxVal;
	if error < 0
		new_val = last_val * (1 + 0.10);
	else
		new_val = last_val / (1 - 0.05);
	end
	corrAudio = filter(1,[1 zeros(1,timeSamp-3) new_val], echoSig);
end

plot(echoCep);

soundsc(corrAudio,fs)

function echoCep = echo_ceps_calc(echoSig,marginSamp)
	echoCep = cepstrum(echoSig);
	echoCep = echoCep(1:round(length(echoCep)/2)+1); % Half to account for symmetry of FFT
	echoCep = echoCep(marginSamp:end); % margin samples for speech cepstrum
	echoCep = abs(echoCep); % dont care for sign
	plot(echoCep); 
	
end