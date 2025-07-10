function y = formant_filter(x, F, BW, G, fs)
%FORMANT_FILTER filters input signal with formant filter
%   Args:
%       x       - input signal
%       F       - array with formant frequencies F = [F1, F2, F3] in Hz
%       B       - array with bandwidth of formant areas B = [B1, B2, B3] in
%       Hz
%       G       - array with gain parameters for each formant
%       fs      - sample frequency
% 
% all filters should be parallel i think
% w = fs/2;
% 
% y  = x  + gain(1) * bandpass(x, [(F(1)-B(1)/2)/w, (F(1)+B(1)/2)/w]) ...
%         + gain(2) * bandpass(x, [(F(2)-B(2)/2)/w, (F(2)+B(2)/2)/w]) ...
%         + gain(3) * bandpass(x, [(F(3)-B(3)/2)/w, (F(3)+B(3)/2)/w]);


%% Variables for testing/free hand synthesis
G = G * 10;

B = cell(1,5);
A = cell(1,5);
for k = 1:length(F)
    wo = F(k)/(fs/2);
    bw = BW(k)/(fs/2);
    [b,a] = iirpeak(wo, bw);
    b = (0.7079/k) * b;
    B{k} = b;
    A{k} = a;
end

%% 3) Sériové zapojení rezonátorů

% y0 = filter(B{1}, A{1}, x);               % hrudní formant
% % %   % ->
%     y1 = y0;
%     for i = 2:floor(length(A)/3)          % sériově
%         y1 = filter(B{i}, A{i}, y1);      % ústní formant
%     end
%     y1 = filter(B{2}, A{2},y0);         
% % % ->
%   y2 = y0;
%   for i=floor(length(A)/3)+1:length(A)    % sériově
%       y2 = filter(B{i}, A{i}, y2);        % nosní formant
%   end
%   y =  y1 + y2;


%paralelně
y = 0;
for i = 1:length(A)
    y = y + G(i) * filter(B{i}, A{i}, x);
end

end

