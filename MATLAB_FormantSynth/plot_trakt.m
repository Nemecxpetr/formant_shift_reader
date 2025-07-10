function plot_trakt(vowel, M, fs)
%PLOT_TRAKT Plots the tract and its shape with set formant points
    
    %%  Modul spectrum of input signal 
    X = 20*log10(abs(fft(vowel)));
    X = X(1:fix(end/2));
    
    %% Inverse filtration
    p = fix(fs/1000)+4;
    
    a = lpc(vowel, p);
    g = filter(a, [1 zeros(1,p)], vowel);
    
    %% Module spectrum of filtered signal
    H = freqz([1 zeros(1,12)], a, 2048, fs);
    H = 20*log10(abs(H))-20;
    
    %% Both spectrum visualisations
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
    xlabel('{\itf} [Hz] \rightarrow');
    ylabel('|{\itS}(e^{j2\pi{\itf}})|, |{\itH}(e^{j2\pi{\itf}})| [dB] \rightarrow');
    legend('Rec','Hlasovy trakt');
end

