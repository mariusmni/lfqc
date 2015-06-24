lpaq8 and lpaq8e are file compressors.

Copyright (C) 2007  Matt Mahoney, Alexander Ratushnyak.

    LICENSE

    This program is free software; you can redistribute it and/or
    modify it under the terms of the GNU General Public License as
    published by the Free Software Foundation; either version 2 of
    the License, or (at your option) any later version.

    This program is distributed in the hope that it will be useful, but
    WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
    General Public License for more details at
    Visit <http://www.gnu.org/copyleft/gpl.html>.

	See http://cs.fit.edu/~mmahoney/compression/ for the latest version.

To compress:
============

  lpaq8 N input output

where N is 0 to 9.
Memory usage is 6 + 3*2^N MB  (9 to 1542 MB).
Larger numbers usually give better compression at similar speed.

To decompress:
==============

  lpaq8 d input output

Decompression requires the same memory as compression.

lpaq8e is a version of lpaq8 tuned for better compression of extra-large
homogeneous files (with uniform statistics). It works like the 'normal' lpaq8.

Contents:
=========

    readme.txt	- This file
    lpaq8.exe	- Windows executable
    lpaq8e.exe	- Windows executable
    lpaq8.cpp	- Source code for both programs. Use -DWIKI to compile lpaq8e

The executables were compiled as follows with MinGW 3.4.2 g++

  g++ -Wall lpaq8.cpp -O2 -Os -march=pentiumpro -fomit-frame-pointer -s -o lpaq8.exe
  g++ -Wall lpaq8.cpp -O2 -Os -march=pentiumpro -fomit-frame-pointer -s -DWIKI -o lpaq8e.exe

and then compressed with Upack 0.399.

Update: Feb. 15, 2008.  .exe files are unpacked, as Upack causes false alarms
with some virus detectors.

History:
========

July 24, 2007 - lpaq1 written by Matt Mahoney.

Sept. 20, 2007 - lpaq2 improved by Alexander Ratushnyak.

Sept. 29, 2007 - lpaq3a and lpaq3e improved by Alexander Ratushnyak.

Oct. 1, 2007 - lpaq4 and lpaq4e improved by Alexander Ratushnyak.

Oct.14, 2007 - lpaq5 and lpaq5e improved by Alexander Ratushnyak.
               This is the 1st time for LPAQ and PAQ algorithms
               to use a set of state tables.

Oct.21, 2007 - lpaq6 and lpaq6e improved by Alexander Ratushnyak.
               A simple realization of E8/E9 transform was added. May have bugs.

Oct.31, 2007 - lpaq7 and lpaq7e improved by Alexander Ratushnyak.

Dec.10, 2007 - lpaq8 and lpaq8e improved by Alexander Ratushnyak.
