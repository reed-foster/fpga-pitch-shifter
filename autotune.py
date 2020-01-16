import matplotlib.pyplot as plt

from math import e, pi, sin, cos, log, floor, ceil
j = 1j

from lib6003.audio import *
import numpy as np

filename = 'sinusoid.wav'
fs = 44100
omega = lambda t: 1000/(2*fs)*(t/2+fs)
sinusoid = [cos(2*pi*t*omega(t)/fs) for t in range(2*fs)]
wav_write(sinusoid, fs, f'sinusoid.wav')

signal, fs = wav_read(filename)
#in_key = [16.35, 18.35, 20.60, 21.83, 24.50, 27.50, 30.87, 32.70, 36.71, 41.20, 43.65, 49.00, 55.00, 61.74, 65.41, 73.42, 82.41, 87.31, 98.00, 110.0, 123.5, 130.8, 146.8, 164.8, 174.6, 196.0, 220.0, 246.9, 261.6, 293.7, 329.6, 349.2, 392.0, 440.0, 493.9, 523.3, 587.3, 659.3, 698.5, 784.0, 880.0, 987.8, 1047, 1175, 1319, 1397, 1568, 1760, 1976, 2093, 2349, 2637, 2794, 3136, 3520, 3951, 4186, 4699, 5274, 5588, 6272, 7040, 7902]

in_key = [16.35, 32.70, 65.41, 130.8, 261.6, 523.3, 1047, 2093, 4186]

def get_scale(dft, in_key, fs):
    k_max = np.abs(dft[:len(dft)//2]).argmax(axis=0)
    f = k_max/len(dft)*fs
    print(f'fundamental frequency: {f}')
    note = min(in_key, key=lambda f0: abs(f0 - f))
    scale_amount = note/f
    return scale_amount

def resample(signal, scale_amount):
    '''
    resample a signal with linear interpolation
    '''
    resampled = []
    for k in range(int(round(len(signal)*scale_amount))):
        k_s = k / scale_amount
        k_prev = floor(k_s) # integer before
        k_next = ceil(k_s) # integer after
        k_prev = k_prev if k_prev < len(signal) else len(signal) - 1
        k_next = k_next if k_next < len(signal) else len(signal) - 1
        resampled.append((k_s - k_prev)*(signal[k_next] - signal[k_prev]) + signal[k_prev])
    return resampled
        

dft_size = 512
step_size = 64
num_ffts = (len(signal) - dft_size)//step_size+ 1
autotuned = np.zeros(len(signal))
window = np.hanning(dft_size) #np.array([1 - cos(2*pi*n/(dft_size - 1)) for n in range(dft_size)])
for bin in range(num_ffts):
    sample = signal[bin*step_size:bin*step_size+dft_size]
    dft = np.fft.fft(np.multiply(sample, window))
    # TODO get actual frequencies (that were split between bins) by doing phase shift stuff
    scale_amount = get_scale(dft, in_key, fs)
    scaled_dft = resample(dft, scale_amount)
    scaled_signal = np.fft.ifft(scaled_dft)
    windowed_scaled_signal = np.multiply(scaled_signal, np.hanning(len(scaled_dft)))
    print(f'scale_amount: {scale_amount}')
    autotuned[bin*step_size:bin*step_size+len(scaled_dft)] = np.add(autotuned[bin*step_size:bin*step_size+len(scaled_dft)], windowed_scaled_signal)

wav_write(autotuned, fs, f'{filename.split(".")[0]}_shifted.wav')
