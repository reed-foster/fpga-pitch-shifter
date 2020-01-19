import matplotlib.pyplot as plt

from math import e, pi, sin, cos, log, floor, ceil
j = 1j

from lib6003.audio import *
import numpy as np

filename = 'voice.wav'
fs = 44100
#omega = lambda t: 1000/(2*fs)*(t/2+fs)
#sinusoid = [cos(2*pi*t*omega(t)/fs) for t in range(2*fs)]
#wav_write(sinusoid, fs, f'sinusoid.wav')

signal, fs = wav_read(filename)
#in_key = [16.35, 18.35, 20.60, 21.83, 24.50, 27.50, 30.87, 32.70, 36.71, 41.20, 43.65, 49.00, 55.00, 61.74, 65.41, 73.42, 82.41, 87.31, 98.00, 110.0, 123.5, 130.8, 146.8, 164.8, 174.6, 196.0, 220.0, 246.9, 261.6, 293.7, 329.6, 349.2, 392.0, 440.0, 493.9, 523.3, 587.3, 659.3, 698.5, 784.0, 880.0, 987.8, 1047, 1175, 1319, 1397, 1568, 1760, 1976, 2093, 2349, 2637, 2794, 3136, 3520, 3951, 4186, 4699, 5274, 5588, 6272, 7040, 7902]

in_key = [16.35, 32.70, 65.41, 130.8, 261.6, 523.3, 1047, 2093, 4186]

def resample(signal, scale_amount, target_size=None):
    '''
    resample a signal with linear interpolation
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
        

dft_size = 1024
step_size_analysis = dft_size#256 
t_a = step_size_analysis/fs

num_ffts = (len(signal) - dft_size)//step_size_analysis+ 1

window = np.ones(dft_size)#np.hanning(dft_size) 

last_phase_synthesis = np.zeros(dft_size)
last_phase_analysis = np.zeros(dft_size)
bin_freq = np.array([k*2*pi/dft_size for k in range(dft_size)])

autotuned = np.zeros(len(signal))

for bin in range(num_ffts):
    sample = signal[bin*step_size_analysis:bin*step_size_analysis+dft_size]
    dft = np.fft.fft(np.multiply(sample, window))

    mag = abs(dft)
    phase = np.arctan2(dft.imag, dft.real)
    last_phase_analysis = phase
    
    # get bin with maximum amplitude
    # ignore DC component
    k_max = mag[1:len(mag)//2].argmax(axis=0)+1
    f_max = k_max/dft_size*fs
    # use phase difference to get closer approximation of fundamental frequency
    f_n = lambda n: (phase[k_max] - last_phase_analysis[k_max] + 2*pi*n)/(2*pi*t_a)
    fundamental = f_n(min(range(step_size_analysis), key=lambda n: abs(f_n(n) - f_max)))
    
    # get scaling factor that shifts fundamental frequency to the nearest "in-key" frequency
    note = min(in_key, key=lambda f0: abs(f0 - fundamental))
    scale_factor = note/fundamental
    
    phase = last_phase_synthesis + 2*pi*fundamental*t_a

    corrected_dft = resample(dft, scale_factor)
    new_signal = np.multiply(resample(np.fft.ifft(corrected_dft), 1/scale_factor, dft_size), window)/(dft_size/step_size_analysis)

    start = int(bin*step_size_analysis)
    end = start + len(new_signal)
    autotuned[start:end] = np.add(autotuned[start:end], new_signal)

wav_write(autotuned, fs, f'{filename.split(".")[0]}_shifted.wav')
