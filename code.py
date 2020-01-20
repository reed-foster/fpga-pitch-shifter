#!/usr/bin/env python
# coding: utf-8

from math import e, pi, sin, cos, log, floor, ceil
j = 1j
from lib6003.audio import *
import numpy as np


# Read input file
filename = 'loch.wav'
signal, fs = wav_read(filename)

# In-key notes

### Cmaj
C_maj = [16.35, 18.35, 20.60, 21.83, 24.50, 27.50, 30.87, 32.70, 36.71, 41.20, 43.65, 49.00, 55.00, 61.74, 65.41, 73.42, 82.41, 87.31, 98.00, 110.0, 123.5, 130.8, 146.8, 164.8, 174.6, 196.0, 220.0, 246.9, 261.6, 293.7, 329.6, 349.2, 392.0, 440.0, 493.9, 523.3, 587.3, 659.3, 698.5, 784.0, 880.0, 987.8, 1047, 1175, 1319, 1397, 1568, 1760, 1976, 2093, 2349, 2637, 2794, 3136, 3520, 3951, 4186, 4699, 5274, 5588, 6272, 7040, 7902]

### C
C = [16.35, 32.70, 65.41, 130.8, 261.6, 523.3, 1047, 2093, 4186]

### middle C
C4 = [261.6]

### Fmin
F_min = [16.35,17.32,19.45,21.83,23.12,25.96,29.14,32.70,34.65,38.89,43.65,46.25,51.91,58.27,65.41,69.30,77.78,87.31,92.50,103.8,116.5,130.8,138.6,155.6,174.6,185.0,207.7,233.1,261.6,277.2,311.1,349.2,370.0,415.3,466.2,523.3,554.4,622.3,698.5,740.0,830.6,932.3,1047,1109,1245,1397,1480,1661,1865,2093,2217,2489,2794,2960,3322,3729,4186,4435,4978,5588,5920,6645,7459]

### CEG Cmaj triad
CEG_triad = [16.35,20.60,24.50,32.70,41.20,49.00,65.41,82.41,98.00,130.8,164.8,196.0,261.6,329.6,392.0,523.3,659.3,784.0,1047,1319,1568,2093,2637,3136,4186,5274,6272]

in_key = CEG_triad


def resample(signal, scale_amount, target_size=None):
    '''
    Resample a signal with linear interpolation
    
    target_size forces the output list to be the right size by duplicating the last item in the signal
    '''
    resampled = []
    if target_size is None:
        target_size=int(round(len(signal)*scale_amount))
    for k in range(target_size):
        k_s = k / scale_amount
        k_prev = floor(k_s) # integer before
        k_next = ceil(k_s) # integer after
        k_prev = k_prev if k_prev < len(signal) else len(signal) - 1
        k_next = k_next if k_next < len(signal) else len(signal) - 1
        resampled.append((k_s - k_prev)*(signal[k_next] - signal[k_prev]) + signal[k_prev])
    return resampled


def find_peaks_hps(dft):
    '''
    Computes a partial Harmonic Product Spectrum of a DFT to find the fundamental frequency
    '''
    product = dft.copy()
    for n in range(2, 5):
        scaled_sig = resample(dft, 1/n)
        pad_diff = len(dft) - len(scaled_sig)
        padded_sig = np.pad(scaled_sig, (0, pad_diff), constant_values=1)
        product = np.multiply(padded_sig, product)
    return product

dft_size = 4096
oversampling_factor = 2 # how much each DFT window hsould overlap
step_size = dft_size//oversampling_factor
t_a = step_size/fs # period between starts of samples

# number of DFTs in entire signal
num_dfts = (len(signal) - dft_size)//step_size+ 1

# keep track of DFT coefficients in previous window
last_phase = np.zeros(dft_size)

# angular bin frequency for each value of "k"
bin_freq = np.array([k*2*pi/dft_size for k in range(dft_size)])

# buffer for output signal
autotuned = np.zeros(len(signal))


###############################################################
# Main loop
###############################################################

for bin in range(num_dfts):

    ###########################################################
    # select a portion of the original signal and take its DFT
    ###########################################################
    sample = signal[bin*step_size:bin*step_size+dft_size]
    dft = np.fft.fft(np.multiply(sample, np.hanning(dft_size)))

    mag = abs(dft)
    phase = np.arctan2(dft.imag, dft.real)
    last_phase = phase
   
    ###########################################################
    # find fundamental frequency
    ###########################################################
    # ignore DFT content above 1200 Hz (provides better results)
    k_cutoff = int(1200*dft_size/fs)
    # find lowest frequency peak in DFT
    k_max = find_peaks_hps(mag[2:k_cutoff]).argmax() + 2 # ignore lowest frequencies
    # the second "harmonic" seems to be the perceived pitch
    k_max *= 2

    f_max = k_max/dft_size*fs # frequency in Hz from DFT index

    # use phase information to more accurately estimate frequency
    # based off of relationship (omega = dphi/dt)
    f_n = lambda n: (phase[k_max] - last_phase[k_max] + 2*pi*n)/(2*pi*t_a)
    # get phase-corrected frequency that is closest to max-amplitude bin frequency
    min_n = min(range(step_size), key=lambda n: abs(f_n(n) - f_max))
    fundamental = f_n(min_n)
    
    ###########################################################
    # calculate scaling factor which clamps the
    # fundamental frequency to a note that is "in key"
    ###########################################################
    note = min(in_key, key=lambda f0: abs(f0 - fundamental))
    scale_factor = note/fundamental
    
    # use linear interpolation to rescale the DFT
    corrected_dft = resample(dft, scale_factor)
    pitch_shifted_sample = resample(np.fft.ifft(corrected_dft), 1/scale_factor, dft_size)
    # divide each sample by oversampling factor so the amplitude of the resultant sum is the same as the original
    new_sample = pitch_shifted_sample/(oversampling_factor)
    
    ###########################################################
    # add new sample to autotuned buffer
    ###########################################################
    start = int(bin*step_size)
    end = start + len(new_signal)
    autotuned[start:end] = np.add(autotuned[start:end], new_signal)

wav_write(autotuned, fs, f'{filename.split(".")[0]}_shifted_CMaj.wav')

