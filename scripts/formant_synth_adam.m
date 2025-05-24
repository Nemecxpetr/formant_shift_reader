close all;
clear;
clc;


%Fa = [700 1220 2600];
Fa = [760 850 1610];
Fe = [390 1910 2300];
Fi = [240 2160 2400];
B = [130 70 160];

dur = 1.0;
fs = 8000;                  % sampling rate
nsamps = floor(dur*fs);     % number of samples
R = exp(-pi*B/fs);          % pole radii
%theta = 2*pi*Fa/fs;          % pole angle
%theta = 2*pi*Fe/fs;
theta = 2*pi*Fi/fs;
poles = R .* exp(j*theta);              % poles
[B,A] = zp2tf(0,[poles,conj(poles)],1); % control
h = freqz(B,A,1024);
h = h/max(h);
hdb = 20*log10(abs(h));

f0 = 200;           % pitch in Hz
w0T = 2*pi*f0/fs;   % normalized frequency

nharm = floor((fs/2)/f0);   % number of harmonics
sig = zeros(1,nsamps);
n = 0:(nsamps-1);

% synthesize bandlimited impulse train
for i=1:nharm
    sig = sig + cos(i*w0T*n);
end

sig = sig/max(sig); % normalize
audiowrite('pulse.wav', sig, fs);
figure(1);
subplot(211);
plot(sig); xlim([0 500]);
title('Impulse train');
xlabel('Time (samples)');
ylabel('Amplitude');

nfft = 1024;
fni = 0:fs/nfft:fs-fs/nfft;


% compute speech vowel
M = 256;        % window size
w = hann(M).';    % hann window
speech = filter(1,A,sig);
audiowrite('synthspeech.wav', speech, fs);

%soundsc([sig,speech],fs);
winspeech = w .* speech(1:length(w));

sigw = w.*sig(1:M);
sigwspec = fft(sigw,nfft);
sigwspecdb = 20*log10(abs(sigwspec)/max(sigwspec));
subplot(212);
plot(fni,sigwspecdb); grid on; axis([0 4000 -80 0]);
title('Spectrum of Impulse train');
xlabel('Frequency (Hz)');
ylabel('Magnitude (dB)');

fni2 = 0:0.5*fs/nfft:0.5*fs-0.5*fs/nfft;

% spectrum of synthetic vowel
sspec = fft(winspeech, nfft);
sspec = sspec/max(sspec);
sspecdb = 20*log10(abs(sspec));
figure(2);
plot(fni2,hdb);  grid on;    axis([0 4000 -60 0]);
title('Spectrum of Filter');
xlabel('Frequency (Hz)');
ylabel('Magnitude (dB)');


figure(3);
subplot(211); 
plot(speech);   xlim([0 500]);
title('Output signal');
xlabel('Time (samples)');
ylabel('Amplitude');

subplot(212);
plot(fni,sspecdb);  grid on;    axis([0 4000 -80 0]);
title('Spectrum of Output');
xlabel('Frequency (Hz)');
ylabel('Magnitude (dB)');


% LPC
LPorder = 12;    % three formants
a = real(lpc(winspeech,LPorder));
y2 = filter(1,a,sig);
smoother = hamming(M).';
a_FIR = filter(1,a,[1,zeros(1,M-1)]);
A_FIR = fft(a_FIR,nfft);
A_FIRdb = 20*log10(abs(A_FIR)/max(A_FIR));
%plot(fni,A_FIRdb,'r');  hold on;

Y = A_FIR .* sspec;
Ydb = 20*log10(abs(Y)/max(Y));
%plot(fni,Ydb,'g');

y = ifft(Y,nfft);
y = real(y);

%figure(2);
%subplot(211);
%plot(winspeech);   hold on;
%subplot(212);
%plot(real(y),'r');

%soundsc(y,fs);
