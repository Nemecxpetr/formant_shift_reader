/*
  ==============================================================================

    This file contains the basic framework code for a JUCE plugin editor.

  ==============================================================================
*/

#pragma once

#include <JuceHeader.h>
#include "PluginProcessor.h"

//==============================================================================
/**
*/
class FormantShiftReaderAudioProcessorEditor  : public juce::AudioProcessorEditor
{
public:
    FormantShiftReaderAudioProcessorEditor (FormantShiftReaderAudioProcessor&);
    ~FormantShiftReaderAudioProcessorEditor() override;

    //==============================================================================
    void paint (juce::Graphics&) override;
    void resized() override;

	//==============================================================================
    juce::Slider freqScaleSlider;
    std::unique_ptr<juce::AudioProcessorValueTreeState::SliderAttachment> freqAttachment;


private:
    // This reference is provided as a quick way for your editor to
    // access the processor object that created it.
    FormantShiftReaderAudioProcessor& audioProcessor;

    JUCE_DECLARE_NON_COPYABLE_WITH_LEAK_DETECTOR (FormantShiftReaderAudioProcessorEditor)
};
