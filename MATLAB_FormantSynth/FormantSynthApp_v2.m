% Formant Synthesizer App
classdef FormantSynthApp_v2 < matlab.apps.AppBase
%% Formant Synth App  formant synthesis sonification of written sentence
% Final project for lecture of Speech Processing at Brno University of Technology
%   1.12 Formant Synthesis
%
%   Author: Bc. Petr Němec
%   ID:     221480
%   Year:   2025 (summer)
%
%   Aim: Create a model of the vocal speech tract with a set of resonators
%   connected in parallel or series;
%   Parameters of each resonator are: 
%       - Frequency
%       - Bandwidth
%       - Gain
%   Input of the system of resonators is a signal from a simulated vocal
%   cord gained by inverse filtration of vowels. 
%   Try modifying the system parameters to change the timbre of the output
%   speech.
%
% Implementation notes:
%   - The model loads recorded vowel samples and extracts formant parameters
%     using LPC (Linear Predictive Coding) analysis.
%   - Formants are resynthesized using parallel peak filters (iirpeak).
%   - Parameters of frequency, bandwidth, and gain can be dynamically adjusted.
%   - Crossfading between vowels is implemented to improve naturalness.
%   - A final synthesized sentence is generated and visualized with a spectrogram.

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                   matlab.ui.Figure
        TextInput                  matlab.ui.control.EditField
        FrequencyScaleSliderLabel  matlab.ui.control.Label
        FrequencyScaleSlider       matlab.ui.control.Slider
        BandwidthScaleSliderLabel  matlab.ui.control.Label
        BandwidthScaleSlider       matlab.ui.control.Slider
        GainScaleSliderLabel       matlab.ui.control.Label
        GainScaleSlider            matlab.ui.control.Slider
        CrossfadeTimeSliderLabel    matlab.ui.control.Label
        CrossfadeTimeSlider          matlab.ui.control.Slider
        ExcitationTypeDropDownLabel matlab.ui.control.Label
        ExcitationTypeDropDown      matlab.ui.control.DropDown
        SynthesizeButton            matlab.ui.control.Button
        SaveWAVButton               matlab.ui.control.Button
        ShowFormantsButton          matlab.ui.control.Button
        UIAxes                      matlab.ui.control.UIAxes
        FormantFreqScales          % <-- NO TYPE
        FormantBWScales            % <-- NO TYPE
        FormantGainScales          % <-- NO TYPE
    end

    properties (Access = private)
        %% App variables 
        % You can set number of formants to be controled here!

        SynthesizedAudio % Audio data
        fs = 16000; % Sampling frequency
        n_for  = 5; % number of formants
        f0 = 120;   % base speech tone for male
    end

    methods (Access = private)

        function createComponents_old(app)
            % Create UIFigure
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 100 800 600];
            app.UIFigure.Name = 'Formant Synthesizer';

            % Create TextInput
            app.TextInput = uieditfield(app.UIFigure, 'text');
            app.TextInput.Position = [50 550 300 22];
            app.TextInput.Value = 'Ahoj světe';

            % Create FrequencyScaleSlider
            app.FrequencyScaleSliderLabel = uilabel(app.UIFigure, 'Text', 'Frequency Scale');
            app.FrequencyScaleSliderLabel.Position = [50 500 100 22];
            app.FrequencyScaleSlider = uislider(app.UIFigure);
            app.FrequencyScaleSlider.Position = [150 510 150 3];
            app.FrequencyScaleSlider.Limits = [0.3 2.5];
            app.FrequencyScaleSlider.Value = 1;

            % Create BandwidthScaleSlider
            app.BandwidthScaleSliderLabel = uilabel(app.UIFigure, 'Text', 'Bandwidth Scale');
            app.BandwidthScaleSliderLabel.Position = [50 450 100 22];
            app.BandwidthScaleSlider = uislider(app.UIFigure);
            app.BandwidthScaleSlider.Position = [150 460 150 3];
            app.BandwidthScaleSlider.Limits = [0.2 2.5];
            app.BandwidthScaleSlider.Value = 1;

            % Create GainScaleSlider
            app.GainScaleSliderLabel = uilabel(app.UIFigure, 'Text', 'Gain Scale');
            app.GainScaleSliderLabel.Position = [50 400 100 22];
            app.GainScaleSlider = uislider(app.UIFigure);
            app.GainScaleSlider.Position = [150 410 150 3];
            app.GainScaleSlider.Limits = [0.1 5];
            app.GainScaleSlider.Value = 1;

            % Create CrossfadeTimeSlider
            app.CrossfadeTimeSliderLabel = uilabel(app.UIFigure, 'Text', 'Crossfade Time (s)');
            app.CrossfadeTimeSliderLabel.Position = [50 350 120 22];
            app.CrossfadeTimeSlider = uislider(app.UIFigure);
            app.CrossfadeTimeSlider.Position = [180 360 150 3];
            app.CrossfadeTimeSlider.Limits = [-0.2 0.5]; % adjust as needed
            app.CrossfadeTimeSlider.Value = 0.1;
            app.CrossfadeTimeSlider.MajorTicks = -0.2:0.1:0.5;
            app.CrossfadeTimeSlider.MinorTicks = -0.2:0.05:0.5;



            % Create ExcitationTypeDropDown
            app.ExcitationTypeDropDownLabel = uilabel(app.UIFigure, 'Text', 'Excitation Type');
            app.ExcitationTypeDropDownLabel.Position = [50 300 100 22];
            app.ExcitationTypeDropDown = uidropdown(app.UIFigure);
            app.ExcitationTypeDropDown.Position = [160 300 100 22];
            app.ExcitationTypeDropDown.Items = {'Buzz (voiced)', 'Noise (unvoiced)', 'Sawtooth'};
            app.ExcitationTypeDropDown.Value = 'Buzz (voiced)';

            % Create per-formant sliders
            formant_labels = {'F1', 'F2', 'F3', 'F4', 'F5'};
            app.FormantFreqScales = gobjects(5,1);
            app.FormantBWScales = gobjects(5,1);
            app.FormantGainScales = gobjects(5,1);

            
            y_start = 200; % starting vertical position
            for k = 1:5
                % Formant Frequency Scale
                uilabel(app.UIFigure, 'Text', ['Freq ' formant_labels{k}], 'Position', [50 y_start 60 22]);
                app.FormantFreqScales(k) = uislider(app.UIFigure, ...
                    'Position', [120 y_start+10 100 3], ...
                    'Limits', [0 2], ...
                    'Value', 1);
            
                % Formant Bandwidth Scale
                uilabel(app.UIFigure, 'Text', ['BW ' formant_labels{k}], 'Position', [230 y_start 60 22]);
                app.FormantBWScales(k) = uislider(app.UIFigure, ...
                    'Position', [300 y_start+10 100 3], ...
                    'Limits', [0.1 2], ...
                    'Value', 1);
            
                % Formant Gain Scale
                uilabel(app.UIFigure, 'Text', ['Gain ' formant_labels{k}], 'Position', [410 y_start 60 22]);
                app.FormantGainScales(k) = uislider(app.UIFigure, ...
                    'Position', [480 y_start+10 100 3], ...
                    'Limits', [0 5], ...
                    'Value', 1);
            
                y_start = y_start - 40; % move down for next formant
            end


            % Create SynthesizeButton
            app.SynthesizeButton = uibutton(app.UIFigure, 'push');
            app.SynthesizeButton.Position = [50 250 100 30];
            app.SynthesizeButton.Text = 'Synthesize';
            app.SynthesizeButton.ButtonPushedFcn = createCallbackFcn(app, @SynthesizeButtonPushed, true);

            % Create SaveWAVButton
            app.SaveWAVButton = uibutton(app.UIFigure, 'push');
            app.SaveWAVButton.Position = [160 250 100 30];
            app.SaveWAVButton.Text = 'Save WAV';
            app.SaveWAVButton.ButtonPushedFcn = createCallbackFcn(app, @SaveWAVButtonPushed, true);

            % Create ShowFormantsButton
            app.ShowFormantsButton = uibutton(app.UIFigure, 'push');
            app.ShowFormantsButton.Position = [270 250 100 30];
            app.ShowFormantsButton.Text = 'Show Formants';
            app.ShowFormantsButton.ButtonPushedFcn = createCallbackFcn(app, @ShowFormantsButtonPushed, true);

            % Create UIAxes
            app.UIAxes = uiaxes(app.UIFigure);
            app.UIAxes.Position = [400 50 350 500];
            title(app.UIAxes, 'Spectrogram');
            xlabel(app.UIAxes, 'Time (s)');
            ylabel(app.UIAxes, 'Frequency (Hz)');

            % Show the figure
            app.UIFigure.Visible = 'on';
        end

        function createComponents(app)
            % Create UIFigure
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 100 1200 600];
            app.UIFigure.Name = 'Formant Synthesizer';
        
            % Create GridLayout
            grid = uigridlayout(app.UIFigure, [1,2]);
            grid.ColumnWidth = {'1x', '2x'};
        
            % Create Left Panel for Controls
            controlPanel = uipanel(grid);
            controlGrid = uigridlayout(controlPanel, [40,1]);
            controlGrid.RowHeight = repmat({'fit'},1,40);
            controlGrid.Scrollable = 'on';

        
            % Create Controls in Left Panel
        
            app.TextInput = uieditfield(controlGrid, 'text');
            app.TextInput.Value = 'Čau lidi';
        
            app.FrequencyScaleSliderLabel = uilabel(controlGrid, 'Text', 'Frequency Scale');
            app.FrequencyScaleSlider = uislider(controlGrid, 'Limits', [0.3 3.3], 'Value', 1);
        
            app.BandwidthScaleSliderLabel = uilabel(controlGrid, 'Text', 'Bandwidth Scale');
            app.BandwidthScaleSlider = uislider(controlGrid, 'Limits', [0.2 3.2], 'Value', 1);
        
            app.GainScaleSliderLabel = uilabel(controlGrid, 'Text', 'Gain Scale');
            app.GainScaleSlider = uislider(controlGrid, 'Limits', [0.1 5.1], 'Value', 1);
        
            app.CrossfadeTimeSliderLabel = uilabel(controlGrid, 'Text', 'Crossfade Time (s)');
            app.CrossfadeTimeSlider = uislider(controlGrid, 'Limits', [-0.2 0.5], 'Value', 0.1);
            app.CrossfadeTimeSlider.MajorTicks =  -0.2:0.1:0.5;
            app.CrossfadeTimeSlider.MinorTicks = -0.2:0.05:0.5;
        
            app.ExcitationTypeDropDownLabel = uilabel(controlGrid, 'Text', 'Excitation Type');
            app.ExcitationTypeDropDown = uidropdown(controlGrid, 'Items', {'Buzz (voiced)', 'Noise (unvoiced)', 'Sawtooth', 'Pink Noise'}, 'Value', 'Buzz (voiced)');
        
            % Buttons
            app.SynthesizeButton = uibutton(controlGrid, 'push', 'Text', 'Synthesize', 'ButtonPushedFcn', createCallbackFcn(app, @SynthesizeButtonPushed, true));
            app.SaveWAVButton = uibutton(controlGrid, 'push', 'Text', 'Save WAV', 'ButtonPushedFcn', createCallbackFcn(app, @SaveWAVButtonPushed, true));
            app.ShowFormantsButton = uibutton(controlGrid, 'push', 'Text', 'Show Formants', 'ButtonPushedFcn', createCallbackFcn(app, @ShowFormantsButtonPushed, true));
        
            uilabel(controlGrid, 'Text', '--- Formant Settings ---', ...
                'FontWeight', 'bold', ...
                'FontSize', 14, ...
                'HorizontalAlignment', 'center');
           
            formantGrid = uigridlayout(controlGrid, [6,3]);
            formantGrid.ColumnWidth = {'1x','1x','1x'};
            formantGrid.RowHeight = repmat({'fit'},1,6);
            formantGrid.Scrollable = 'off';

            uilabel(formantGrid, 'Text', 'Freq', ...
                'FontWeight', 'bold', 'HorizontalAlignment', 'center');
            uilabel(formantGrid, 'Text', 'BW', ...
                'FontWeight', 'bold', 'HorizontalAlignment', 'center');
            uilabel(formantGrid, 'Text', 'Gain', ...
                'FontWeight', 'bold', 'HorizontalAlignment', 'center');

            % Per-formant sliders (F1-F5)
            formant_labels = {'F1', 'F2', 'F3', 'F4', 'F5'};
            app.FormantFreqScales = gobjects(5,1);
            app.FormantBWScales = gobjects(5,1);
            app.FormantGainScales = gobjects(5,1);
            
            for k = 1:app.n_for
                app.FormantFreqScales(k) = uislider(formantGrid, ...
                    'Limits', [0 2], 'Value', 1);
            
                app.FormantBWScales(k) = uislider(formantGrid, ...
                    'Limits', [0.1 2], 'Value', 1);
            
                app.FormantGainScales(k) = uislider(formantGrid, ...
                    'Limits', [0 5], 'Value', 1);
            end


            % Create Right Panel for Spectrogram
            app.UIAxes = uiaxes(grid);
            title(app.UIAxes, 'Spectrogram');
            xlabel(app.UIAxes, 'Time (s)');
            ylabel(app.UIAxes, 'Frequency (Hz)');
            app.UIAxes.Layout.Row = 1;
            app.UIAxes.Layout.Column = 2;
        
            % Show the figure
            app.UIFigure.Visible = 'on';
        end


        function SynthesizeButtonPushed(app, ~)
            %% Variables 
            text = app.TextInput.Value;
            freq_scale = app.FrequencyScaleSlider.Value;
            bw_scale = app.BandwidthScaleSlider.Value;
            gain_scale = app.GainScaleSlider.Value;
            crossfade_time = app.CrossfadeTimeSlider.Value;
            excitation_type = app.ExcitationTypeDropDown.Value;
            app.fs = app.fs;
            app.n_for = app.n_for; %number of formants

            silence_length = abs(crossfade_time)*1.3; % Dynamicaly change with crossfade
            
            
            %% Simple assign letter to sound
            % for ch = 1:length(text)
            %     [X{ch}, app.fs] = assign_sample(text(ch), 1.3*crossfade_time);
            % end

            %% Assign letter to sound advanced with czech 'ch'
            phonemes = parse_czech_text(app.TextInput.Value);
            
            X = {}; % reset
            for idx = 1:length(phonemes)
                [X{idx}, app.fs] = assign_sample(phonemes{idx}, 1.3*crossfade_time);
            end

            %% Create sentence from assigned letters 
            n = round(crossfade_time * app.fs);
            sentence = zeros(2*n,1);

            for i = 1:length(X)
                vowel = X{i};
                if sum(vowel) == 0
                    xx = vowel;
                    sentence = [sentence; xx];
                else
                    %% Formant analysis of recorded letters for frequency, bandwith and gain formant filter paramaters estimation
                    % Could be also set to parameters manually.
                    [F, B, G] = formanty(vowel, app.fs, app.n_for);
                    winlen = hamming(256);
                    winover = 128;
                    app.f0 = f0_autokor(vowel, winlen, winover, app.fs);

                    % Apply formant modifications
                    F = F * freq_scale;
                    B = B * bw_scale;
                    G = G * gain_scale;

                    % Read per-formant scales
                    formant_freq_scales = arrayfun(@(s) s.Value, app.FormantFreqScales);
                    formant_bw_scales   = arrayfun(@(s) s.Value, app.FormantBWScales);
                    formant_gain_scales = arrayfun(@(s) s.Value, app.FormantGainScales);
                    
                    % Apply individual scaling
                    n_for_used = length(F); % in case fewer formants detected
                    F = F .* formant_freq_scales(1:n_for_used).';
                    B = B .* formant_bw_scales(1:n_for_used).';
                    G = G .* formant_gain_scales(1:n_for_used).';
            
                    %% Choose excitation type
                    switch excitation_type
                        %% Excitor is previously inverse filtered voice
                        % For time resolution of syllabels like b, c, d, s,
                        % etc. ... each letter was inverse filtered
                        % individually
                        case 'Buzz (voiced)'                  
                            xx = formant_filter(invfilter(vowel, app.fs), F, B, G, app.fs);
                        %% Excitor is noise
                        case 'Noise (unvoiced)'
                            vow = randn(size(vowel));       % load input signal as noise
                            x = 0.03*(vow./max(abs(vow)));   % normalize between -1 and 1 and reduce gain to match speech loudness
                            x = preemfaze(x);
                            B = B * 0.6; % noise is harsh so better make the formants sharper as well as lower gain
                            G = G * 0.6;
                            xx = formant_filter(x, F, B, G, app.fs);
                        %% Excitor is sawtooth wave
                        case 'Sawtooth'
                            app.f0 = app.f0; % fundamental frequency, typical male pitch
                            t = (0:length(vowel)-1)'/app.fs;
                            saw = 2*(t*app.f0 - floor(0.5 + t*app.f0)); % normalized sawtooth between -1 and 1
                            x = 0.05*(saw .* hann(length(saw)));       % window it nicely
                            x = preemfaze(x);
                            saw_gain_correction = 0.2;           % adjust gain to avoid overpowering
                            B = B*0.8;
                            G = G*0.8;
                            xx = saw_gain_correction * formant_filter(x, F, B, G, app.fs);
                        case 'Pink Noise'
                            vow = pinknoise(size(vowel));
                            x = 0.03*(vow./max(abs(vow)));   % normalize between -1 and 1 and reduce gain to match speech loudness
                            x = preemfaze(x);
                            B = B * 0.6; % noise is harsh so better make the formants sharper as well as lower gain
                            G = G * 0.6;
                            xx = formant_filter(x, F, B, G, app.fs);                            
                        otherwise
                            error('Unknown excitation type!');
                    end

                    %% Crossfade between each letter
                    % Calculate crossfade length
                    n = round(crossfade_time * app.fs);
                    
                    % Make sure n does not exceed available lengths
                    max_n = min(length(sentence), length(xx));
                    n = min(n, max_n);
                    
                    if n > 0
                        W = linspace(1,0,n).';
                        sentence1 = sentence(1:end-n);
                        crossfade = sentence(end-n+1:end) .* (W) + xx(1:n) .* (1-W);
                        sentence2 = xx(n+1:end);
                        sentence = [sentence1; crossfade; sentence2];
                    elseif n < 0
                        silence = generate_silence(silence_length, app.fs);
                        sentence = [sentence; silence; xx];
                    else
                        % If no crossfade possible, just concatenate
                        sentence = [sentence; xx];
                    end
                end
            end
            
            %% Play synthesized sound
            app.SynthesizedAudio = sentence;
            sound(app.SynthesizedAudio, app.fs);
            
            %% Print spectrogram of synthesised sound
            n_fft = 4096;
            hop = round(n_fft/8);
            winlen = hann(n_fft/4);
            [S,F,T] = spectrogram(app.SynthesizedAudio, winlen, hop, n_fft, app.fs);
            S_dB = 20*log10(abs(S)+eps);
            imagesc(app.UIAxes, T, F, S_dB);
            axis(app.UIAxes, 'xy');
            ylim(app.UIAxes, [50 round(app.fs/2-0.2*app.fs)]);
            clim(app.UIAxes, [-60, 20]);
            colormap(app.UIAxes, jet);
            colorbar(app.UIAxes);
            title(app.UIAxes, 'Spectrogram');
            xlabel(app.UIAxes, 'Time (s)');
            ylabel(app.UIAxes, 'Frequency (Hz)');
        end

        function SaveWAVButtonPushed(app, ~)
            if isempty(app.SynthesizedAudio)
                uialert(app.UIFigure, 'No audio synthesized yet!', 'Error');
                return;
            end
            [file,path] = uiputfile('*.wav','Save synthesized audio');
            if ischar(file)
                audiowrite(fullfile(path,file), app.SynthesizedAudio, app.fs);
            end
        end

        function ShowFormantsButtonPushed(app, ~)
            close all;
            if isempty(app.SynthesizedAudio)
                uialert(app.UIFigure, 'No audio synthesized yet!', 'Error');
                return;
            end
            plot_trakt(app.SynthesizedAudio, app.fs);
            title('Approximate Formant Spectrum');
            xlabel('Frequency Bin');
            ylabel('Amplitude');
            grid on;
        end

    end

    methods (Access = public)

        function app = FormantSynthApp_v2
            createComponents(app);
        end

    end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Local Functions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function parsed = parse_czech_text(text)
% PARSE_CZECH_TEXT Parses input Czech text into phoneme tokens.
% Handles special Czech rules: ch, dě, tě, ně, bě, pě, vě.
parsed = {}; % Initialize empty cell array
i = 1;
text = lower(text); % work in lowercase
while i <= strlength(text)
    if i < strlength(text) && text(i) == 'c' && text(i+1) == 'h'
        % Special Czech "ch"
        parsed{end+1} = 'ch';
        i = i + 2;

    elseif i < strlength(text) && text(i+1) == 'ě'
        % Handle softening before ě
        softened_map = containers.Map({'d', 't', 'n'}, {'ď', 'ť', 'ň'});
        je_insertion_letters = {'b', 'p', 'v'};

        current_char = text(i);

        if isKey(softened_map, current_char)
            % d, t, n → softened (ď, ť, ň) + e
            parsed{end+1} = softened_map(current_char);
            parsed{end+1} = 'e';

        elseif any(strcmp(current_char, je_insertion_letters))
            % b, p, v → b + j + e
            parsed{end+1} = current_char;
            parsed{end+1} = 'j';
            parsed{end+1} = 'e';

        else
            % Any other consonant + ě → consonant + e
            parsed{end+1} = current_char;
            parsed{end+1} = 'e';
        end

        i = i + 2; % skip both letters

    elseif i < strlength(text) && any(text(i+1) == ['i', 'í'])
        % Handle softening before i or í
        softened_map = containers.Map({'d', 't', 'n'}, {'ď', 'ť', 'ň'});

        current_char = text(i);

        if isKey(softened_map, current_char)
            % d, t, n + i or í → softened + i or í
            parsed{end+1} = softened_map(current_char);
            parsed{end+1} = text(i+1); % keep i or í
            i = i + 2;
            continue;
        end

        % Otherwise treat normally
        parsed{end+1} = current_char;
        i = i + 1;

    else
        % Normal character (including space)
        parsed{end+1} = text(i);
        i = i + 1;
    end
end
end

function [sample, fs] = assign_sample(char, silence_length)
% ASSIGN_SAMPLE Assigns a sample to a given character.
%   Inputs:
%       char - Character input
%       silence_length - Length of silence if character not found (seconds)
%   Outputs:
%       sample - Audio sample corresponding to character
%       fs - Sampling rate

persistent samples fs_loaded file_map_characters

if nargin < 2
    silence_length = 0.5; % seconds
end

if isempty(samples)
    disp('Loading samples into memory...');

    file_map_characters = containers.Map(...
        {'a', 'á', 'b', 'c', 'č', 'd', 'ď', 'e', 'é', 'eé', 'f', 'g', 'h', ...
         'ch', 'i', 'í', 'j', 'k', 'lj', 'l', 'm', 'n', 'ň', 'o', 'ó', ...
         'p', 'k_', 'qk', 'kv', 'rr', 'r', 'ř', 's', '_š_', 'š', 't', 'ť', ...
         'u', 'ú', 'ů', 'v', 'w', '_ks_', 'x', 'z', 'y', 'i2', 'ý', 'z2', 'ž_', 'ž', ...
         'a-', 'e-', 'i-', 'o-', 'u-'}, ...
        {'1-a.wav', '2-á.wav', '3- b.wav', '4-c.wav', '5-č.wav', '6-d.wav', '7-ď.wav', ...
         '8-e.wav', '9-é.wav', '10-eé.wav', '11-f.wav', '12- g.wav', '13-h.wav', ...
         '14-ch.wav', '15-i.wav', '16-í.wav', '17-j.wav', '18-k.wav', '19-lj.wav', ...
         '20-l.wav', '21-m.wav', '22-n.wav', '23-ň.wav', '24-o.wav', '25-ó.wav', ...
         '26-p.wav', '27-k_.wav', '28-qk.wav', '29-kv.wav', '30-rr.wav', '31-r.wav', ...
         '32-ř.wav', '33-s.wav', '34-_š_.wav', '35-š.wav', '36-t.wav', '37-ť.wav', ...
         '38-u.wav', '39-ú.wav', '40-ů.wav', '41-v.wav', '42-w.wav', '43-_ks_.wav', ...
         '44-ks.wav', '45-z.wav', '46-y.wav', '47-i.wav', '48-ý.wav', '49-z.wav', ...
         '50-ž_.wav', '51-ž.wav', '52-a-.wav', '53-e-.wav', '54-i-.wav', ...
         '55-o-.wav', '56-u-.wav'});

    samples = containers.Map(); % use a Map for safe matching

    for k = keys(file_map_characters)
        char_key = k{1};
        filename = fullfile('samples', 'Mixdown', file_map_characters(char_key));
        [audio, local_fs] = audioread(filename);

        if isempty(fs_loaded)
            fs_loaded = local_fs;
        elseif local_fs ~= fs_loaded
            warning('Sample %s has different sampling rate!', filename);
        end

        % CONVERT TO MONO here!
        if size(audio,2) > 1
            audio = mean(audio, 2);
        end

        samples(char_key) = audio; % save by original char
    end
end

char = lower(char);

if char == ' '
    % Space = silence
    sample = generate_silence(silence_length, fs_loaded);
elseif isKey(samples, char)
    sample = samples(char);
else
    % Unknown character = silence
    sample = generate_silence(silence_length, fs_loaded);
end

fs = fs_loaded;
end

function y = invfilter(x, fs)
% INVFILTER Performs inverse filtering to extract excitation.
p = fix(fs/1000)+4;
a = lpc(x, p);
y = filter(a, [1 zeros(1,p)], x);
end

function [F, B, G] = formanty(x, fs, n_for)
% FORMANTY Extracts realistic formants from a vowel sample.

if nargin<3
    n_for = 3;
end

x = preemfaze(x, 0.95); % strong preemphasis
X = x;

order = round(fs/1000)*2; % better LPC order

a = lpc(X, order);

z = roots(a.');
z = z(imag(z)>0);

tmp_F = (angle(z)/(2*pi))*fs;
tmp_B = ((-log(abs(z)))/pi)*fs;

% Filter unrealistic formants
idx = (tmp_B < 700) & (tmp_F > 90) & (tmp_F < 5000);
tmp_F = tmp_F(idx);
tmp_B = tmp_B(idx);

[H,w] = freqz(1,a,2048,fs);

[tmp_F, index] = sort(tmp_F);
tmp_B = tmp_B(index);

n_valid = min(n_for, length(tmp_F));
G = zeros(1,n_for);
F = zeros(1,n_for);
B = zeros(1,n_for);

for j = 1:n_valid
    F(j) = tmp_F(j);
    B(j) = tmp_B(j);
    [~, idx2] = min(abs(w - F(j)));
    G(j) = abs(H(idx2));
end
end

function y = formant_filter(x, F, BW, G, fs)
% FORMANT_FILTER Synthesizes vowel-like sounds by applying formant filters.
G = G * 10;

B = cell(1,length(F));
A = cell(1,length(F));
for k = 1:length(F)
    if F(k) <= 0 || F(k) >= (fs/2 * 0.95)
        continue;
    end
    wo = F(k)/(fs/2);
    bw = BW(k)/(fs/2);
    [b,a] = iirpeak(wo,bw);
    B{k} = b;
    A{k} = a;
end

y = 0;
for i = 1:length(A)
    if isempty(B{i}) || isempty(A{i})
        continue;
    end
    y = y + G(i) * filter(B{i}, A{i}, x);
end
y = y/length(A); % to compensate for the paralelization
end

function y = preemfaze(x, alfa)
% PREEMFAZE Applies pre-emphasis to signal.
if nargin<2
    alfa = 0.95;
end
y = filter([1 -alfa], [1 0], x);
end

function plot_trakt(vowel, fs)
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
hold off;
grid on;
axis tight;
xscale("log");
xlabel('f [Hz]');
ylabel('|S(f)|, |H(f)| [dB]');
legend('Recorded','LPC Model');
title('Spectrum and Formant Model');
end

function silence = generate_silence(silence_length, fs)
%%GENERATE SILENCE generates silence with length set by input parameter in
%%samples
silence = zeros(round(silence_length * fs), 1);
end

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
%X = segmentace(x, winlen, winover);

%% Vypocet F0 pomoci autokorelacni funkce
%F0 = zeros(size(X,2),1); % Alokace pameti

%for i = 1:size(X,2)
    %c = xcorr(X(:,i));
    c = xcorr(x);
    c = fftshift(c);
    
    % Nalezeni pozice lokalniho maxima
    [tmp, pozice] = max(c(s_low:s_high));
    lag = pozice + s_low - 1;
    
    % Vypocet F0
    %F0(i) = fs/lag;
    F0 = fs/lag;
%end
end

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
end