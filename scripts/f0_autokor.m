function F0 = f0_autokor(x, winlen, winover, fs)
% This function returns F0 computed with autocorelation
% 
%   Args:
%       x         - input signal sequence
%       winlen    - window length or window itself
%       winover   - hop size lenght
%       fs        - signal sample rate
%   Returns:
%       F0        - column vector with F0

%% Promenne
f_low = 75; % Spodni hranice F0
f_high = 400; % Horni hranice F0

s_high = fix(fs/f_low); % Spodni hranice ve vzorcich
s_low = fix(fs/f_high); % Horni hranice ve vzorcich

%% Segmentace signalu
seg = segmentace(x, winlen, winover);

%% Vypocet F0 pomoci autokorelacni funkce
F0 = zeros(size(seg,2),1); % Alokace pameti

for i = 1:size(seg,2)
    c = xcorr(seg(:,i));
    c = fftshift(c);
    
    % Nalezeni pozice lokalniho maxima
    [tmp, pozice] = max(c(s_low:s_high));
    lag = pozice + s_low - 1;
    
    % Vypocet F0
    F0(i) = fs/lag;
end