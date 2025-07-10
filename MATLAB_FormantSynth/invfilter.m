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

