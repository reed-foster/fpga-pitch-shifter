#!/usr/bin/env python
# coding: utf-8

# !pip3 install numpy matplotlib
# !pip3 install https://sigproc.mit.edu/_static/fall19/software/lib6003-0.0.4.tar.gz
# !pip3 install peakutils
 
# import peakutils # Peak finding with spacing and threshold

import matplotlib.pyplot as plt
from math import e, pi, sin, cos, log, floor, ceil
from lib6003.audio import *
import numpy as np
j = 1j


# Setup of input file
# filename = 'sinusoid.wav'
filename = 'audio_samples/celine.wav'
# filename = 'note.wav'
signal, fs = wav_read(filename)

# In-key notes

## C Maj
# in_key = [16.35, 18.35, 20.60, 21.83, 24.50, 27.50, 30.87, 32.70, 36.71, 41.20, 43.65, 49.00, 55.00, 61.74, 65.41, 73.42, 82.41, 87.31, 98.00, 110.0, 123.5, 130.8, 146.8, 164.8, 174.6, 196.0, 220.0, 246.9, 261.6, 293.7, 329.6, 349.2, 392.0, 440.0, 493.9, 523.3, 587.3, 659.3, 698.5, 784.0, 880.0, 987.8, 1047, 1175, 1319, 1397, 1568, 1760, 1976, 2093, 2349, 2637, 2794, 3136, 3520, 3951, 4186, 4699, 5274, 5588, 6272, 7040, 7902]

## C Only
# in_key = [16.35, 32.70, 65.41, 130.8, 261.6, 523.3, 1047, 2093, 4186]

## C4
# in_key = [261]

## F Min
# in_key = [16.35,17.32,19.45,21.83,23.12,25.96,29.14,32.70,34.65,38.89,43.65,46.25,51.91,58.27,65.41,69.30,77.78,87.31,92.50,103.8,116.5,130.8,138.6,155.6,174.6,185.0,207.7,233.1,261.6,277.2,311.1,349.2,370.0,415.3,466.2,523.3,554.4,622.3,698.5,740.0,830.6,932.3,1047,1109,1245,1397,1480,1661,1865,2093,2217,2489,2794,2960,3322,3729,4186,4435,4978,5588,5920,6645,7459]

## CEG C Maj triad
in_key = [16.35,20.60,24.50,32.70,41.20,49.00,65.41,82.41,98.00,130.8,164.8,196.0,261.6,329.6,392.0,523.3,659.3,784.0,1047,1319,1568,2093,2637,3136,4186,5274,6272]

## C Pentatonic
# in_key = []
# notes = [32.703, 36.708, 41.203, 49, 55]
# for i in range(7):
#     for j in notes:
#         in_key.append(j*2**i)

def resample(signal, scale_amount, target_size=None):
    '''
    resample a signal with zero order hold, force resizing to fit target_size
    '''
    resampled = []
    if target_size is None:
        target_size=int(round(len(signal)*scale_amount))
    for k in range(target_size):
        k_s = k / scale_amount
        k_prev = min(floor(k_s), len(signal) - 1)# integer before
        
        resampled.append(signal[k_prev])
    return resampled

def resample_dft(dft, scale_amount):
    '''
    resample a dft spectrum with zero order hold, mirrors output to create valid dft

    returns: scaled dft spectrum with same size as input
    '''
    resampled = np.zeros(len(dft), dtype=np.complex64)

    # DC offset k = 0, last possible bin size//2+1, mirror 1 - size//2+1 to size - size//2+1 
    # Creates a scaled version of the first half of DFT, truncates if necessary
    center_bin = len(dft)//2
    end_idx = 0
    if scale_amount >= 1: 
        end_idx = center_bin
    else:
        end_idx = int((len(dft) * scale_amount)//2)

    for k in range(end_idx + 1):
        k_s = k / scale_amount
        k_prev = min(ceil(k_s), center_bin) # integer before
        
        resampled[k] = dft[k_prev]
        
    for i in range(center_bin+1, len(dft)):
        mirrored_idx = 2*center_bin-i
        resampled[i] = np.conj(resampled[mirrored_idx])
    
    return resampled

def find_peaks_hps(signal):
  '''
  Computes partial harmonic product spectrum of DFT to find fundamental frequency

  Global max peak should be fundamental freq, input is a subset of dft, up to 1500 Hz
  '''
  clean_sig = signal.copy()

  product = clean_sig.copy()
  for n in range(2, 4):
    scaled_sig = resample(clean_sig, 1/n)
    pad_diff = len(clean_sig) - len(scaled_sig)
    padded_sig = np.pad(scaled_sig, (0, pad_diff), constant_values=0)
    product = np.multiply(padded_sig, product)
  
  ## Graphics stuff
  # plt.figure()
  # plt.xscale('log')

  # idx = product.argmax()
  
  # # idx = signal[max(hps_idx-5, 0): min(hps_idx+5, len(signal))].argmax() + max(hps_idx-5, 0)
  # # peaks = peakutils.indexes(signal, thres=15, min_dist=10, thres_abs=True)
  # # for peak_idx in peaks:
  # #     plt.plot(peak_idx, signal[peak_idx], 'bs')

  # plt.plot(idx, 50, 'ro')
  # plt.ylim(0,200)
  # plt.plot(clean_sig)
  # plt.show()

  return product

#################################################################
dft_size = 4096
step_size_analysis = dft_size//2
t_a = step_size_analysis/fs

num_ffts = (len(signal) - dft_size)//step_size_analysis+ 1

window = np.ones(dft_size)

last_phase_synthesis = np.zeros(dft_size)
last_phase_analysis = np.zeros(dft_size)
bin_freq = np.array([k*2*pi/dft_size for k in range(dft_size)])

autotuned = np.zeros(len(signal))

prev_values = [0, 0]
dft_data = []

for bin in range(num_ffts):

    ###########################################################
    # select a portion of the original signal and take its DFT
    ###########################################################
    sample = signal[bin*step_size_analysis:bin*step_size_analysis+dft_size]
    dft = np.fft.fft(np.multiply(sample, window))
    mag = abs(dft)
    phase = np.arctan2(dft.imag, dft.real)

    ###########################################################
    # find fundamental frequency
    ###########################################################
    # ignore DFT content above 1500 Hz, better performance
    k_cutoff = int(1500*dft_size/fs)
    k_max = find_peaks_hps(np.concatenate((np.zeros(1), mag[1:k_cutoff]))).argmax()
    # fundamental freq via dft
    f_max = k_max/dft_size*fs
    
    # use phase information to more accurately estimate frequency
    # based off of relationship (omega = dphi/dt)
    f_n = lambda n: (phase[k_max] - last_phase_analysis[k_max] + 2*pi*n)/(2*pi*t_a)

    min_n = round((last_phase_analysis[k_max]-phase[k_max])/(2*pi) + f_max * t_a)
    fundamental = f_n(min_n)
    
    last_phase_analysis = phase

    ###########################################################
    # calculate scaling factor which clamps the
    # fundamental frequency to a note that is "in key"
    ###########################################################

    note = min(in_key, key=lambda f0: abs(f0 - fundamental))
    scale_factor = note/fundamental

    # scale_factor = 1.9
    # print(scale_factor)

    corrected_dft = resample_dft(dft, scale_factor)
    new_signal = np.fft.ifft(corrected_dft)/(dft_size/step_size_analysis)

    ###########################################################
    # add new sample to autotuned buffer
    ###########################################################
    start = int(bin*step_size_analysis)
    end = start + len(new_signal)
    autotuned[start:end] = np.add(autotuned[start:end], new_signal)

    # plt.figure()
    # # plt.plot(sample)
    # # plt.plot(new_signal)
    # # print(dft)
    # # print(new_signal)
    # plt.plot(dft)
    # plt.plot(corrected_dft)
    # plt.show()
    
wav_write(autotuned, fs, f'{filename.split(".")[0]}_tuned.wav')
