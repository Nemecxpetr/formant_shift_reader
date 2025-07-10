function y = segmentace(x, winlen, winover)

% y = segmentace(x, winlen, winover)
% 
% This function segments the signal
% x         - input signal
% winlen    - length of window (in samples) or the window
% winover   - overlap in samples
% y         - output matrix where the each segment is stored in column

%% Check the winlength and overlap
wl = 0;
winover = floor(winover);

if(length(winlen) > 1)
    wl = length(winlen);
else
    wl = winlen;
end

%% Obtain the number of columns
cols = ceil((length(x)-winover)/(wl-winover));

%% Padd by zeros if necessary
if(mod(length(x),wl) ~= 0)
    x(end+1:cols*wl) = 0;
end

%% Prepare matrix
y = zeros(wl, cols);

%% Segment
sel = (1:wl).';
step = 0:(wl-winover):(cols-1)*(wl-winover);

y(:) = x(sel(:,ones(1,cols)) + step(ones(1,wl),:));

%% Apply window
if(length(winlen) > 1)
    y = y.*winlen(:,ones(1,cols));
end
