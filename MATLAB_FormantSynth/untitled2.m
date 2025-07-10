%% Uvodni Cistka

close all;
clear;
clc;

%% 1) Parametry filtrů
fs        = 48000;                                  % vzorkovací frekvence [Hz]
%fc        = [ 500, 1000, 2000, 4000, 8000 ];        % střední frekvence rezonátorů [Hz]
fc        = [ 200, 1550, 2200, 4780, 8000 ];
%fc        = [ 80, 250, 570, 980, 2000 ];
BW        = [  50,  100,  200,  400,  800 ];         % šířka pásma (–3 dB) [Hz]
gain_dB   = [   0,  -3,    6,    0,  -6 ];           % zisk v decibelech
gain      = 10.^(gain_dB/20);                       % zisk v lineární škále

B = cell(1,5);
A = cell(1,5);
for k = 1:5
    wo = fc(k)/(fs/2);
    bw = BW(k)/(fs/2);
    [b,a] = iirpeak(wo, bw);
    b = gain(k) * b;
    B{k} = b;
    A{k} = a;
    fprintf('Res %d: fc=%4d Hz, BW=%4d Hz, gain=%+3d dB\n', k, fc(k), BW(k), gain_dB(k));
end

%% 2) Načtení samohlásek a inverzní filtrace (LPC reziduál)
% Předpokládáme, že ve složce máte WAV soubor se samohláskami nazvaný 'vowels.wav'
[vow, fs_vow] = audioread('samples/Mixdown/2-á.wav');   
if fs_vow ~= fs
    vow = resample(vow, fs, fs_vow);            % přeuspořádání, pokud jiná vzork. frekvence
end
vow = mean(vow,2);                              % směrování na mono

% LPC analýza: pořad = 12
lk = 12;
a_lpc = lpc(vow, lk);                          % odhad LPC koeficientů
residual = filter(a_lpc, 1, vow);               % inverzní filtrace → reziduální signál

% Vstup do kaskády rezonátorů
x = residual;

%% 3) Sériové zapojení rezonátorů
y = x;
for i = 1:5
    y = filter(B{i}, A{i}, y);
end

%% 4) Poslech / uložení výsledku
soundsc(y, fs);                            % odposlech
% audiowrite('output_resonators.wav', y, fs);

%% 5) (Volitelné) Porovnání spekter původního reziduálu a výstupu
figure; 
subplot(2,1,1); pwelch(x,[],[],[],fs); title('Reziduál po inverzní filtraci');
subplot(2,1,2); pwelch(y,[],[],[],fs); title('Výstup kaskády rezonátorů');
