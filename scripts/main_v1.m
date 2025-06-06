clc;
close all;
clear variables;

%% Main parameters
text = 'ojoj co to je';
silence_length = 1; % seconds
crossfade = 0.1; % seconds crossfade between vowels

%% Parameter    | Good Range
% freq_scale    | 0.7 to 1.5
% bw_scale      | 0.5 to 2.0
% gain_scale    | 0.5 to 2.0
formant_frequency_scale  = 1; % 1.0 = no shift, >1 = up, <1 = down
formant_bandwidth_scale  = 1.0; % 1.0 = normal, >1 = wider
formant_gain_scale       = 1.4; % 1.0 = normal, >1 = louder resonances

n_for = 5; % number of formants to use

%% Load samples and create sentence
for ch = 1:length(text)
    [X{ch}, fs] = assign_sample(text(ch), silence_length);
end

y = sonify_sentence(X, fs, crossfade, n_for, formant_frequency_scale, formant_bandwidth_scale, formant_gain_scale);

%% Play sound
sound(y, fs);

%% Plot spectrogram of the synthesized sentence
[S,F,T] = spectrogram(y, hann(512), 256, 1024, fs);
S_dB = 20*log10(abs(S) + eps);

figure;
imagesc(T, F, S_dB);
axis xy;
ylim([0 5000]);
colormap(jet);
colorbar;
title('Spectrogram of Synthesized Sentence (0-5kHz)');
xlabel('Time [s]');
ylabel('Frequency [Hz]');
clim([-80 0]);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Local Functions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [sample, fs] = assign_sample(char, silence_length)
% ASSIGN_SAMPLE Assigns a sample to a given character.
%   Inputs:
%       char - Character input
%       silence_length - Length of silence if character not found (seconds)
%   Outputs:
%       sample - Audio sample corresponding to character
%       fs - Sampling rate

persistent samples fs_loaded

if nargin < 2
    silence_length = 0.5; % seconds
end

if isempty(samples)
    disp('Loading samples into memory...');
    file_map = {
    'a',   '1-a.wav';
    'á',   '2-á.wav';
    'b',   '3- b.wav';
    'c',   '4-c.wav';
    'č',   '5-č.wav';
    'd',   '6-d.wav';
    'ď',   '7-ď.wav';
    'e',   '8-e.wav';
    'é',   '9-é.wav';
    'eé',  '10-eé.wav';
    'f',   '11-f.wav';
    'g',   '12- g.wav';
    'h',   '13-h.wav';
    'ch',  '14-ch.wav';
    'i',   '15-i.wav';
    'í',   '16-í.wav';
    'j',   '17-j.wav';
    'k',   '18-k.wav';
    'lj',  '19-lj.wav';
    'l',   '20-l.wav';
    'm',   '21-m.wav';
    'n',   '22-n.wav';
    'ň',   '23-ň.wav';
    'o',   '24-o.wav';
    'ó',   '25-ó.wav';
    'p',   '26-p.wav';
    'k_',  '27-k_.wav';
    'qk',  '28-qk.wav';
    'kv',  '29-kv.wav';
    'rr',  '30-rr.wav';
    'r',   '31-r.wav';
    'ř',   '32-ř.wav';
    's',   '33-s.wav';
    '_š_', '34-_š_.wav';
    'š',   '35-š.wav';
    't',   '36-t.wav';
    'ť',   '37-ť.wav';
    'u',   '38-u.wav';
    'ú',   '39-ú.wav';
    'ů',   '40-ů.wav';
    'v',   '41-v.wav';
    'w',   '42-w.wav';
    '_ks_', '43-_ks_.wav';
    'x',   '44-ks.wav';
    'z',   '45-z.wav';
    'y',   '46-y.wav';
    'i2',  '47-i.wav';
    'ý',   '48-ý.wav';
    'z2',  '49-z.wav';
    'ž_',  '50-ž_.wav';
    'ž',   '51-ž.wav';
    'a-',  '52-a-.wav';
    'e-',  '53-e-.wav';
    'i-',  '54-i-.wav';
    'o-',  '55-o-.wav';
    'u-',  '56-u-.wav';
    };

    samples = struct();
    for i = 1:size(file_map,1)
        key = file_map{i,1};
        filename = fullfile('samples', 'Mixdown', file_map{i,2});
        [audio, fs] = audioread(filename);
        samples.(matlab.lang.makeValidName(key)) = audio;
    end
    fs_loaded = fs;
end

char = lower(char);
key = matlab.lang.makeValidName(char);

if isfield(samples, key)
    sample = samples.(key);
else
    sample = zeros(round(silence_length * fs_loaded), 1);
end

fs = fs_loaded;
end

function sentence = sonify_sentence(X, fs, crossfade, n_for, freq_scale, bw_scale, gain_scale)
% SONIFY_SENTENCE Concatenates and processes phoneme samples into a full sentence.
%   Inputs:
%       X - Cell array of phoneme samples
%       fs - Sampling rate
%       crossfade - Crossfade length in seconds
%       n_for - Number of formants to analyze
%       freq_scale - Formant frequency scaling
%       bw_scale - Formant bandwidth scaling
%       gain_scale - Formant gain scaling
%   Output:
%       sentence - Final synthesized waveform

n = crossfade * fs;

for j = 1:length(X)
    x = X{j};
    if size(x,2) > 1
        x = x(:,1);
    end
    x = x ./ max(abs(x));
    x = x .* hann(length(x));
    x = preemfaze(x);
    X{j} = x;
end

sentence = zeros(2*n,1);
for i = 1:length(X)
    vowel = X{i};
    if sum(vowel) == 0
        xx = vowel;
        sentence = [sentence; xx];
    else
        [F, B, G] = formanty(vowel, fs, n_for);

        % Apply formant modifications
        % F = F * freq_scale;
        % B = B * bw_scale;
        % G = G * gain_scale;

        xx = formant_filter(invfilter(X{i}, fs), F, B, G, fs);
       
        plot_trakt(xx, F, fs);
        plot_trakt(vowel, F, fs);
        
        W = linspace(1,0,n).';
        sentence1 = sentence(1:end-n);
        crossfade = sentence(end-n+1:end) .* (1-W) + xx(1:n) .* W;
        sentence2 = xx(n+1:end);

        sentence = [sentence1; crossfade; sentence2];
    end
end
end

function y = invfilter(x, fs)
% INVFILTER Performs inverse filtering to extract excitation.
p = fix(fs/1000)+4;
a = lpc(x, p);
y = filter(a, [1 zeros(1,p)], x);
end

function [F, B, G] = formanty(x, fs, n_for)
% FORMANTY Extracts formants from a vowel sample.
%   Inputs:
%       x - Input vowel
%       fs - Sampling rate
%       n_for - Number of formants to extract
%   Outputs:
%       F - Formant frequencies
%       B - Bandwidths
%       G - Gains

if nargin<3
    n_for = 3;
end

x = preemfaze(x, 0.01);
X = x;

a = lpc(X, 2*n_for);

z = roots(a.');
z = z(imag(z)>0);

tmp_F = (angle(z)/(2*pi))*fs;
tmp_B = ((-log(abs(z)))/pi)*fs;

[H,w] = freqz(1,a,2048,fs);

[tmp_F, index] = sort(tmp_F);
tmp_B = tmp_B(index);

G = zeros(1,n_for);
F = zeros(1,n_for);
B = zeros(1,n_for);

n_valid = min(n_for, length(tmp_F));
for j = 1:n_valid
    F(j) = tmp_F(j);
    B(j) = tmp_B(j);
    [~, idx] = min(abs(w - F(j)));
    G(j) = abs(H(idx));
end
end

function y = formant_filter(x, F, BW, G, fs)
% FORMANT_FILTER Synthesizes vowel-like sounds by applying formant filters.
G = G * 10;

B = cell(1,length(F));
A = cell(1,length(F));
for k = 1:length(F)
    if F(k) <= 0
        continue;
    end
    wo = F(k)/(fs/2);
    bw = BW(k)/(fs/2);
    [b,a] = iirpeak(wo,bw);
    B{k} = b;
    A{k} = a;
end

y = zeros(size(x));
for i = 1:length(A)
    if isempty(B{i}) || isempty(A{i})
        continue;
    end
    y = y + G(i) * filter(B{i}, A{i}, x);
end
end

function y = preemfaze(x, alfa)
% PREEMFAZE Applies pre-emphasis to signal.
if nargin<2
    alfa = 0.92;
end
y = filter([1 -alfa], [1 0], x);
end

function plot_trakt(vowel, M, fs)
% PLOT_TRAKT Plots LPC model over recorded spectrum.
X = 20*log10(abs(fft(vowel)));
X = X(1:fix(end/2));
p = fix(fs/1000)+4;
a = lpc(vowel, p);
H = freqz(1, a, 2048, fs);
H = 20*log10(abs(H));

figure;
f = linspace(0,fs/2,length(X));
ff = linspace(0,fs/2,length(H));
plot(f,X);
hold on;
plot(ff,H,'r','LineWidth',1.5);
xline(M);
hold off;
grid on;
axis tight;
xscale("log");
xlabel('f [Hz]');
ylabel('|S(f)|, |H(f)| [dB]');
legend('Recorded','LPC Model');
title('Spectrum and Formant Model');
end
