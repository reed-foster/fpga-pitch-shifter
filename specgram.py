import matplotlib.pyplot as plt
import matplotlib.ticker as ticker
import math
#from math import e, pi, sin, cos, log
j = 1j

from lib6003.audio import *

# you should include your dft_c function from the FFT lab, renamed to be called
# fft.

def fft(x):
    N = len(x)
    assert N & (N - 1) == 0
    if N == 1:
        return x
    even = fft(x[::2])
    odd = fft(x[1::2])
    return [1/2*(X_k[0] + X_k[1]*math.e**(-2j*math.pi*k/N)) for k, X_k in enumerate(zip(even+even, odd+odd))]

def stft(x, window_size, step_size, sample_rate):
    # return a Short-Time Fourier Transform of x, using the specified window
    # size and step size.
    # return your result as a list of lists, where each internal list represents
    # the DFT coefficients of one window.  I.e., output[n][k] should represent
    # the kth DFT coefficient from the nth window.
    num_windows = (len(x) - window_size)//step_size+1
    return [fft(x[i*step_size:i*step_size+window_size]) for i in range(num_windows)]


def k_to_hz(k, window_size, step_size, sample_rate):
    # return the frequency in Hz associated with bin number k in an STFT with
    # the parameters given above.
    return k/window_size*sample_rate

def hz_to_k(freq, window_size, step_size, sample_rate):
    # return the k value associated with the given frequency in Hz, in an STFT
    # with the parameters given above, rounded to the nearest integer.
    return round(freq/sample_rate*window_size)

def timestep_to_seconds(i, window_size, step_size, sample_rate):
    # return the real-world time in seconds associated with the middle
    # of the ith window in an STFT using the parameters given above, rounded to
    # the nearest .01 seconds.
    return round((window_size/2+i*step_size)/sample_rate, 2)

def transpose(x):
    # return the transpose of the input, which is given as a list of lists
    return [[x[n][k] for n in range(len(x))] for k in range(len(x[0]))]


def spectrogram(X, window_size, step_size, sample_rate):
    # X is the output of the stft function (a list of lists of DFT
    # coefficients) this function should return the spectrogram (magnitude
    # squared of the STFT).
    # it should be a list that is indexed first by k and then by i, so that
    # output[k][i] represents frequency bin k in analysis window i.
    return [[abs(x)**2 for x in X_k] for X_k in transpose(X)]

def plot_spectrogram(sgram, window_size, step_size, sample_rate, name):
    # the code below will uses matplotlib to display a spectrogram.  it uses
    # your k_to_hz and timestep_to_seconds functions to label the horizontal
    # and vertical axes of the plot.
    # amplitudes are plotted on a log scale, since human perception of loudness
    # is roughly logarithmic.
    width = len(sgram[0])
    height = (len(sgram)//2+1)  # only plot values up to N/2

    plt.imshow([[math.log(i) if i > 0 else -80 for i in j] for j in sgram[:height+1]], aspect=width/height)
    plt.axis([0, width-1, 0, height-1])

    ticks = ticker.FuncFormatter(lambda x, pos: '{0:.1f}'.format(timestep_to_seconds(x, window_size, step_size, sample_rate)))
    plt.axes().xaxis.set_major_formatter(ticks)
    ticks = ticker.FuncFormatter(lambda y, pos: '{0:.0f}'.format(k_to_hz(y, window_size, step_size, sample_rate)))
    plt.axes().yaxis.set_major_formatter(ticks)

    plt.xlabel('time [s]')
    plt.ylabel('frequency [Hz]')
    plt.title(name)

    plt.colorbar()
    plt.show()


def makesgram(fname, window_size, step_size):
    signal, f_samp = wav_read(fname)
    plot_spectrogram(spectrogram(stft(signal, window_size, step_size, f_samp), window_size, step_size, f_samp), window_size, step_size, f_samp, fname) 


#makesgram('mystery1.wav', 1024, 1024)
#makesgram('mystery2.wav', 1024, 1024)
#makesgram('mystery3.wav', 1024, 1024)
#makesgram('signal.wav', 1024, 256)
makesgram('signal_shifted.wav', 1024, 256)
