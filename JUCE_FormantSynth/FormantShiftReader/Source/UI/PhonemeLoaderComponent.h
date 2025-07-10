// Full-featured JUCE Component for phoneme mapping
#pragma once

#include <JuceHeader.h>
#include <unordered_map>

struct PhonemeSample {
    juce::File file;
    juce::AudioSampleBuffer buffer;
    double sampleRate = 44100.0;
};

class PhonemeLoaderComponent : public juce::Component {
public:
    PhonemeLoaderComponent() {
        phonemeSymbols = { "a", "e", "i", "o", "u" }; // Extend as needed

        for (const auto& phoneme : phonemeSymbols) {
            auto* label = new juce::Label({}, phoneme);
            addAndMakeVisible(label);
            labels.add(label);

            auto* button = new juce::TextButton("Load");
            button->onClick = [this, phoneme] { loadPhonemeFile(phoneme); };
            addAndMakeVisible(button);
            loadButtons.add(button);

            auto* playButton = new juce::TextButton("Play");
            playButton->onClick = [this, phoneme] { playPhoneme(phoneme); };
            addAndMakeVisible(playButton);
            playButtons.add(playButton);
        }

        formatManager.registerBasicFormats();
    }

    void resized() override {
        auto area = getLocalBounds().reduced(10);
        int rowHeight = 30;

        for (int i = 0; i < phonemeSymbols.size(); ++i) {
            auto row = area.removeFromTop(rowHeight);
            labels[i]->setBounds(row.removeFromLeft(50));
            loadButtons[i]->setBounds(row.removeFromLeft(100));
            playButtons[i]->setBounds(row.removeFromLeft(100));
        }
    }

    const std::unordered_map<juce::String, PhonemeSample>& getPhonemeMap() const {
        return phonemeMap;
    }

private:
    juce::OwnedArray<juce::Label> labels;
    juce::OwnedArray<juce::TextButton> loadButtons;
    juce::OwnedArray<juce::TextButton> playButtons;

    std::vector<juce::String> phonemeSymbols;
    std::unordered_map<juce::String, PhonemeSample> phonemeMap;

    juce::AudioFormatManager formatManager;
    std::unique_ptr<juce::AudioTransportSource> transport;
    juce::AudioFormatReaderSource* readerSource = nullptr;
    juce::AudioDeviceManager deviceManager;
    juce::AudioSourcePlayer sourcePlayer;
    std::unique_ptr<juce::FileChooser> activeChooser;

    void loadPhonemeFile(const juce::String& phoneme) {
        activeChooser = std::make_unique<juce::FileChooser>(
            "Select a .wav file for " + phoneme,
            juce::File{},
            "*.wav"
        );

        activeChooser->launchAsync(
            juce::FileBrowserComponent::openMode | juce::FileBrowserComponent::canSelectFiles,
            [this, phoneme](const juce::FileChooser& fc)
            {
                auto file = fc.getResult();
                if (file.existsAsFile())
                    loadFileForPhoneme(phoneme, file);
                activeChooser.reset();
            }
        );
    }

    void loadFileForPhoneme(const juce::String& phoneme, const juce::File& file) {
        std::unique_ptr<juce::AudioFormatReader> reader(formatManager.createReaderFor(file));

        if (reader != nullptr) {
            juce::AudioSampleBuffer buffer((int)reader->numChannels, (int)reader->lengthInSamples);
            reader->read(&buffer, 0, (int)reader->lengthInSamples, 0, true, true);

            phonemeMap[phoneme] = PhonemeSample{ file, std::move(buffer), reader->sampleRate };
        }
    }

    void playPhoneme(const juce::String& phoneme) {
        if (phonemeMap.find(phoneme) == phonemeMap.end()) return;

        auto& sample = phonemeMap[phoneme];
        auto* reader = formatManager.createReaderFor(sample.file);

        if (reader != nullptr) {
            std::unique_ptr<juce::AudioFormatReaderSource> newSource(new juce::AudioFormatReaderSource(reader, true));
            transport.reset(new juce::AudioTransportSource());
            transport->setSource(newSource.get(), 0, nullptr, sample.sampleRate);

            deviceManager.initialise(0, 2, nullptr, true);
            sourcePlayer.setSource(transport.get());
            deviceManager.addAudioCallback(&sourcePlayer);

            readerSource = newSource.release();
            transport->start();
        }
    }
};
