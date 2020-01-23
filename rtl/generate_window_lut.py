#!/usr/bin/env python
# coding: utf-8

import numpy as np

for x in np.hanning(4096):
    print("%03X, " % int(x*512), end='')

print(';')

