function [F, B, G] = formanty(x, fs, n_for)

% [F, B] = formanty(x, winlen, winover, fs)
% 
% Tato funkce vraci formantove kmitocty a odpovidajici sirky pasem.
% 
% x         - sloupcovy vektor
% fs        - vzorkovaci kmitocet
% n_for     - number of formants
%
% F         - vystupni matice formatu (kazdy sloupec odpovida jednomu
%             formantu)
% B         - vystupni matice sirek pasma (kazdy sloupec odpovida jedne
%             sirce)
% G         - vystupni matice zesileni formantu (kazdy sloupec odpovida
%             jednomu fomrantu)
if nargin<3
    n_for = 3; % default compute for 3 formants
end

%% Preemfaze
x = preemfaze(x, 0.01);

%% Segmentace 
% in case we wanted to compute it dynamically for each segment
% TODO: could be added as condition for an imput argument of the function
% X = segmentace(x, winlen, winover);
X = x;
%% Vypocet koeficientu LPC
a = lpc(X, fix(fs/1000)+2);
a = a.';

N = size(a, 2);

%% Vypocet formantu a sirek pasma
F = zeros(N, n_for);
B = zeros(N, n_for);
G = zeros(N, n_for);

for i = 1:N    
    z = roots(a(:,i).'); % Nalezeni korenu citatele prenosove funkce
    z = z(imag(z) > 0);  % Vyber korenu, kde Im{z} > 0

    tmp_F = (angle(z)/(2*pi))*fs;   % Formanty
    tmp_B = ((-log(abs(z)))/pi)*fs; % Sirka pasem

    % Compute gain from frequency response
    [H, w] = freqz(1, a(:,i), 2048, fs);
    
    % Sort formants
    [tmp_F, index] = sort(tmp_F);
    tmp_B = tmp_B(index);
    
    tmp_G = zeros(1,n_for);
    for j = 1:n_for
        [~, idx] = min(abs(w - tmp_F(j)));
        tmp_G(j) = abs(H(idx));
    end
    
    F(i,:) = tmp_F(1:n_for);
    B(i,:) = tmp_B(1:n_for);
    G(i,:) = tmp_G(1:n_for);
end