LFQC - Fastq compressor
Copyright: Marius Nicolae, 2015

* Prerequisites:
- Unix system with at least 4gb of RAM (preferably 8)
- Ruby


Change directory to lfqc/

* To compress:

ruby lfqc.rb file.fastq  -> creates archive file.fastq.lfqc

ruby lfqc.rb -ls454 file.fastq
ruby lfqc.rb -solid file.fastq  -> same as above but specifies type of dataset
ruby lfqc.rb -solexa file.fastq


* To uncompress:

ruby lfqcd.rb file.fastq.lfqc -> uncompresses to file.fastq (dataset type does not matter)

ruby lfqcd.rb file.fastq.lfqc output.fastq -> uncompresses to output.fastq 


* Troubleshooting execution errors

Lfqc depends on two compression algorithms: zpaq and lpaq. Their binaries are included in the archive but they may not work on your system. Fortunately, their source code is also included so you can build them on your machine.

Please try to run the zpaq binary with no arguments. It should print usage. If it doesn't print usage, you have to delete the binary and run make in the zpaq folder. This should regenerate zpaq for your machine.

Similarly, try to run the lpaq binary. It should print usage options. If it doesn't, you have to delete the binary and run make. Lpaq is a bit old so it requires some 32 bit libraries. If your machine is 64 bit you may have to first install some 32 bit libraries. The following guide should help:

http://www.cyberciti.biz/tips/compile-32bit-application-using-gcc-64-bit-linux.html


