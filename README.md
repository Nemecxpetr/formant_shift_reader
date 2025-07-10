# 🎙️ FORMANT SHIFT READER

A text-to-speech plugin based on **formant synthesis**, capable of:

- shifting **all formants** simultaneously or **each individually**
- changing the **excitation signal** (e.g. waveform type)
- loading custom **phoneme samples**
- working as a **VST plugin** via the JUCE framework

---

## 📌 Goals

- [x] Create a working MATLAB prototype for formant analysis and synthesis
- [x] Implement initial JUCE plugin structure (Editor + Processor)
- [x] Add `freqScale` parameter and slider
- [x] Implement phoneme file loading with `PhonemeLoaderComponent`
- [ ] Display and control full Czech phoneme set
- [ ] Enable smooth morphing between phonemes
- [ ] Implement formant shifting DSP (based on LPC or filters)
- [ ] Integrate resynthesis engine using excitation + filter model
- [ ] Allow saving/loading phoneme presets
- [ ] Finalize GUI layout with full editing control
- [ ] Export as fully working VST3 plugin

---

## 🧪 Matlab Prototype

Originally built as a final project for the *Speech Processing* class at **Brno University of Technology**, this MATLAB app performs:

- formant analysis using **LPC**
- vowel synthesis from phoneme waveforms
- interactive control over formants and excitation types
- crossfade-based morphing between phonemes
- GUI interface for inputting text and manipulating synthesis

---

## 🧱 VST Plugin (JUCE + C++)

The plugin version is currently in development. It uses the [JUCE](https://juce.com/) framework and supports:

- `freqScale` slider (global formant shifting)
- phoneme sample loader (early-stage UI prototype)
- basic audio pass-through processing
- modular architecture for DSP and UI expansion

---

## 📂 Structure

```
📁 Source/
│   ├── PluginProcessor.{h,cpp}        # Audio processing logic
│   ├── PluginEditor.{h,cpp}           # GUI for parameters
│   └── UI/
│       └── PhonemeLoaderComponent.h   # Load/play phoneme .wav files
```

---

## 🎯 Next Steps

- Implement real-time formant shifting based on LPC coefficients
- Expand the phoneme loader to support full presets and diphones
- Create interactive text-to-speech interface using loaded phonemes
- Finalize standalone app & VST versions with preset management

---

## 🧠 Inspiration

Inspired by classic formant synthesizers and academic research in text-driven vocal synthesis.

---

## 🔗 License

MIT License (see `LICENSE` file)

---

*Feel free to clone, fork, experiment or contribute!*
