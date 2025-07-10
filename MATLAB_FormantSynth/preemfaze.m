function y = preemfaze(x, alfa)

% y = preemfaze(x, alfa)
% 
% This function does preemphasis using high-pass filter
% x     - input signal
% alfa  - coefficient used during filtering (default 0.92)
% y     - output signal

%% Variables and constants
if(nargin < 2)
    alfa = 0.92;
end

%% Filter signal
y = filter([1 -alfa], [1 0], x);