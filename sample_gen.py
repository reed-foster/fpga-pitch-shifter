import math

num_samp = 48000 # Total num of samples
freq = 440 # Hz sine wave
ampl = 2**12 # Sig p-p
gamma = 0.9
offset = ampl//2

output_str = ""

for i in range(1, num_samp+1):
    val = math.sin(2 * math.pi * freq * i / num_samp)
    signal = int(offset + (val * offset * gamma))
    
    output_str += "{:03x}".format(signal)
    if i % 10 == 0:
        output_str += "\n"
    else:
        output_str += " "
with open("sample_input.txt", "w") as f:
    f.write(output_str)
    f.close()
