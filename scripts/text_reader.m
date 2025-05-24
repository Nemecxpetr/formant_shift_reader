clc;
close all;
clear variables;
%%
text = 'ojoj co to je';
silence_length = 1;

%%
for ch=1:length(text)
    [X{ch}, fs] = assign_sample(text(ch));
end

y = sonify_sentence(X, 0.1, fs);
%%
sound(y, fs);
%%
function [sample, fs] = assign_sample(char, silence_length)
% assigns sample with corresponding letter pronounced to a character input
% uses persistent memory to load samples only once for better performance

persistent samples fs_loaded

if nargin < 2
    silence_length = 0.5; % seconds
end

if isempty(samples)
    % First call: load everything
    disp('Loading samples into memory...');

    % File mapping
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
        '_ks_','43-_ks_.wav';
        'x',   '44-ks.wav';
        'z',   '45-z.wav';
        'y',   '46-y.wav';
        'i2',  '47-i.wav'; % duplicate i
        'ý',   '48-ý.wav';
        'z2',  '49-z.wav'; % duplicate z
        'ž_',  '50-ž_.wav';
        'ž',   '51-ž.wav';
        'a-',  '52-a-.wav';
        'e-',  '53-e-.wav';
        'i-',  '54-i-.wav';
        'o-',  '55-o-.wav';
        'u-',  '56-u-.wav'
        };
    
    samples = struct();
    
    for i = 1:size(file_map,1)
        key = file_map{i,1};
        filename = fullfile('samples', 'Mixdown', file_map{i,2});
        [audio, fs] = audioread(filename);
        samples.(matlab.lang.makeValidName(key)) = audio;
    end
    fs_loaded = fs; % save sample rate
end

char = lower(char);
key = matlab.lang.makeValidName(char); % safe field name

% Assign sample
if isfield(samples, key)
    sample = samples.(key);
else
    sample = zeros(round(silence_length * fs_loaded), 1); % silence if not found
end

fs = fs_loaded;
end

function sentence = sonify_sentence(X, n, fs)
%% SONIFY_SENTENCE formant synthesis sonification of written sentence
% Final project for lecture of Speech Processing at Brno University of technology
%   1.12 Formant Synthesis
%
%   Author: Bc. Petr Němec
%   ID:     221480
%   Year:   2025 (summer)
%
%   Aim: Create a model of the vocal speech tract with a set of resonators
%   connected in parallel or series;
%   Parameters of each resonator are: 
%       frequency
%       bandwith
%       gain.
%   Input of the system of resonators is a signal from a simulated vocal
%   cord gained by inverse filtration of vowels. 
%   Try modifiing the system parameters to change the timbre of the output
%   speech.
%% Variables
    n = n*fs; % crossfade; could be made dynamical
    n_for = 12; % Number of formants to be synthesised analyzed

    %% Pre processing
    for j=1:length(X)
        x = X{j};
        if size(x, 2) % convert audio to mono
            x = x(:, 1);
        end
        x = x./max(abs(x));         % normalize between -1 and 1
        x = x.*hann(length(x));   % multiply with window
        x = preemfaze(x);           % preemphase lowpass filtering
        X{j}= x;
    end  
    
    %% Formant analysis
    % Odhad formantovych kmitoctu
    sentence = zeros(2*n, 1);
    for i=1:length(X)
        vowel = X{i};
        if sum(vowel)==0 %check for silence
           xx = vowel;
           sentence = [sentence; xx];
        else
        % Odhad formantovych kmitoctu
        [F, B, G] = formanty(vowel, fs, n_for);
        % In case formants are computed for segmented signal obtain final
        % freqs by median
            % M = median(F);
            % N = median(B);
        % Check whats being computed
        % plot_trakt(vowel, F, fs);
    %% Formant filter design
        %fc        = [ 500, 1000, 2000, 4000, 8000 ];        % střední frekvence rezonátorů [Hz]
        %F        = [ 300, 1100, 2500, 8500 ];
        %fc        = [ 80, 250, 570, 980, 2000 ];
        %BW        = [  100,  200,  400,  800 ];         % šířka pásma (–3 dB) [Hz]
        %G   = [   8,  -3, -14, -12];                    % zisk v decibelech
        %gain      = (10.^(G/20))/10;                         % zisk v lineární škále
        xx = formant_filter(invfilter(X{i}, fs), F, B, G, fs);
        % plot_trakt(xx, F, fs)
        
        %% crossfading          
        W = linspace(1,0,n).';   
        
        sentence1 = sentence(1:end-n);
        crossfade = sentence(end-n+1:end).*(1-W) + xx(1:n).*W;
        sentence2 = xx(n+1:end);

        sentence = [sentence1; crossfade; sentence2];
        end
    end
end

function y = invfilter(x, fs)
% Computes inverse filter of the vocal cord base on formant lpc analysis
%   Args:
%       x           - input signal sequence
%       fs          - sample frequency
%   Returns
%       y           - filtered signal sequence
%% Vypocet radu linearni predikce
p = fix(fs/1000)+4;

a = lpc(x, p);
y = filter(a, [1 zeros(1,p)], x);

% figure;
% subplot(2, 1, 1); plot(x);
% subplot(2, 1, 2); plot(y);
end