/*
  ==============================================================================

    This file contains the basic framework code for a JUCE plugin editor.

  ==============================================================================
*/

#include "PluginProcessor.h"
#include "PluginEditor.h"

//==============================================================================
FormantShiftReaderAudioProcessorEditor::FormantShiftReaderAudioProcessorEditor (FormantShiftReaderAudioProcessor& p)
    : AudioProcessorEditor (&p), audioProcessor (p)
{
    // Set window size
    setSize (400, 300);

    freqScaleSlider.setSliderStyle(juce::Slider::LinearHorizontal);
    freqScaleSlider.setTextBoxStyle(juce::Slider::TextBoxBelow, false, 80, 20);
    addAndMakeVisible(freqScaleSlider);

    freqAttachment = std::make_unique<juce::AudioProcessorValueTreeState::SliderAttachment>(
        audioProcessor.parameters, "freqScale", freqScaleSlider);
}

FormantShiftReaderAudioProcessorEditor::~FormantShiftReaderAudioProcessorEditor()
{
}

//==============================================================================
void FormantShiftReaderAudioProcessorEditor::paint (juce::Graphics& g)
{
    // (Our component is opaque, so we must completely fill the background with a solid colour)
    g.fillAll (getLookAndFeel().findColour (juce::ResizableWindow::backgroundColourId));

    g.setColour (juce::Colours::white);
    g.setFont (juce::FontOptions (15.0f));
    g.drawFittedText ("Hello World!", getLocalBounds(), juce::Justification::centred, 1);
}

void FormantShiftReaderAudioProcessorEditor::resized()
{
    freqScaleSlider.setBounds(20, 20, getWidth() - 40, 50);
}
