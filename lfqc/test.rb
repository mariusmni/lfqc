
require 'benchmark'
require_relative 'lfqc.rb'
require_relative 'lfqcd.rb'

def main
  _SOLEXA='#SOLEXA'
  _LS454='#LS454'
  _SOLiD='#SOLiD'

  date=Time.new.strftime("%Y-%m-%d_%H:%M:%S")
#  $stdout.reopen("log/out-#{date}.txt", "w")
#  $stderr.reopen("log/err-#{date}.txt", "w")

  currentDir = Dir.pwd
  type = nil
  ARGV.each do |fileName|
    if (fileName == _LS454 || fileName == _SOLiD || fileName == _SOLEXA)
      type = fileName
    end
    if (fileName[0] != '#')
      fileName = File.expand_path(fileName, currentDir)
      print "Compressing #{fileName}\n"
      tm = Benchmark.measure do
        storeQualNoEOL = type == _SOLEXA
        lfqc = LFQC.new(fileName, storeQualNoEOL)
        lfqc.compress
      end
      print "lfqc #{fileName} #{tm}\n"
      print "lfqcSize #{fileName} #{fileSize(fileName + '.lfqc')}\n"
      
      compFileName = fileName + '.lfqc'
      print "Uncompressing #{compFileName}\n"
      uncompFileName = fileName + '_dec'
      tm = Benchmark.measure do
        uncompFileName = LFQCD.new.decompress(compFileName, uncompFileName)
      end
      print "lfqcd #{fileName} #{tm}\n"
      print "lfqcdSize #{uncompFileName} #{fileSize(uncompFileName)}\n"
      
      system("diff -q #{fileName} #{uncompFileName}")
      if $?.success? then
        print "[OK] Compression ok for #{fileName}!\n"
      else
        print "[ERROR] Mismatch for #{fileName}!\n"
        exit
      end
      
    end
  end
end

ARGV=[
'#LS454',
'test/SRR001471.filt.fastq_tiny_ls454',
'#SOLiD',
'test/SRR007215_1.filt.fastq_tiny_solid',
'#SOLEXA',
'test/SRR013951_2.filt.fastq_tiny_solexa'
]

main
