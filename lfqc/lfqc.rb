require 'pathname'
require 'securerandom'
require 'fileutils'

require_relative 'utils.rb'
require_relative 'CompressionMethod.rb'
require_relative 'LPAQCompressionMethod.rb'
require_relative 'ZPAQCompressionMethod.rb'

$cm = Hash.new
$cm["lpaq"] = LPAQCompressionMethod.new
$cm["zpaq"] = ZPAQCompressionMethod.new

class LFQC
  def initialize(filePath, storeQualNoEOL=false, nameCompMethod = $cm['zpaq'], dataCompMethod = $cm['lpaq'], qualCompMethod = $cm['zpaq'])
    @filePath = filePath
    pn = Pathname.new(filePath)
    @fileName = pn.basename.to_s
    @fileDir = pn.dirname
    @workDir  = File.join(@fileDir, 'tmp_' + SecureRandom.hex()  + '_' + @fileName)
    print "Work dir #{@workDir}\n"
    @nameFile= @fileName + '_name'
    @dataFile = noEOLName(@fileName + '_data')
    @qualFile = @fileName + '_qual'
    if (storeQualNoEOL)
      @qualFile = noEOLName(@qualFile)
    end
    @nameFilePath = File.join(@workDir, @nameFile)
    @dataFilePath = File.join(@workDir, @dataFile)
    @qualFilePath = File.join(@workDir, @qualFile)
    @nameCompMethod = nameCompMethod
    @dataCompMethod = dataCompMethod
    @qualCompMethod = qualCompMethod
    @storeQualNoEOL = storeQualNoEOL
    @readLength = -1
  end

  def compress
    print "Splitting fastq...\n"
    FileUtils.mkdir_p(@workDir)
    splitFastq()

    thread = Thread.new do
      print "Compressing data...\n"
      tm = Benchmark.measure do
        Dir.chdir(@workDir)
        @dataCompMethod.archive(@dataFile)
      end
      print "Data compression time #{tm}\n"
    end

    thread2 = Thread.new do
      print "Compressing qual...\n"
      tm = Benchmark.measure do
        Dir.chdir(@workDir)
        @qualCompMethod.archive(@qualFile)
      end
      print "Qual compression time #{tm}\n"
    end

    print "Processing names...\n"
    Dir.chdir(@workDir)
    nameDir = 'nameDir'
    FileUtils.mkdir_p(nameDir)
    separateFields(@nameFilePath, nameDir)
    bestFiles = processNameFiles(nameDir)

    thread2.join # wait for quality compression to terminate

    print "Compressing names...\n"
    tm = Benchmark.measure do
      Dir.chdir(@workDir)
      Dir.chdir(nameDir)
      nameFiles = bestFiles + ['sep']
      @nameCompMethod.archive2(@nameCompMethod.zippedName(separateFieldsFileName(@nameFilePath)), nameFiles.join(' '))
    end
    print "Name compression time #{tm}\n"

    # wait for data compression to terminate
    thread.join

    tarAll()

    print "Clean up...\n"
    cleanUp()
    print "Done.\n"
  end

  def tarAll
    archive = File.join(@fileDir, @fileName + '.lfqc')
    Dir.chdir(@workDir)
    print "Bundling all to #{archive}...\n"
    zName = @nameCompMethod.zippedName(separateFieldsFileName(@nameFile))
    zData = @dataCompMethod.zippedName(@dataFile)
    zQual = @qualCompMethod.zippedName(@qualFile)
    if File.exist?(archive)
      File.delete(archive)
    end
    cmd = "tar cf #{archive} #{zName} #{zData} #{zQual}"
    print "Running #{cmd}\n"
    system(cmd)
  end

  def cleanUp
    cmd = "rm -rf #{@workDir}"
    system(cmd)
  end

  def splitFastq
    first = true
    File.open(@nameFilePath, 'w') do |fname|
      File.open(@dataFilePath, 'w') do |fdata|
        File.open(@qualFilePath, 'w') do |fqual|
          File.open(@filePath,'r') do |f|
            loop do
              # sequence name
              break if not name = f.gets
              fname.write(name)

              # dna
              break if not data = f.gets
              data.chomp! # no EOL
              fdata.write(data)

              # +
              break if not plus = f.gets

              # quality score
              break if not qual = f.gets
              if (@storeQualNoEOL)
                qual.chomp!
                if (first)
                  @readLength = qual.length
                  fqual.write("#{@readLength}\n")
                  first = false
                end
              end
              fqual.write(qual)
            end
          end
        end
      end
    end
  end

  def separateFieldsFileName(fileName)
    fileName + '_sep'
  end

  def separateFields(fileName, dirName)
    delimiters = '.:= _/-'
    #    splitPattern = /([#{delimiters}])/
    #    splitPattern = /(?<=[#{delimiters}])/
    splitPattern = /[#{delimiters}]/
    columnFiles = Hash.new { |hash, key| hash[key] = File.open(File.join(dirName, key.to_s), 'w') }
    File.open(fileName,'r') do |f|
      line = f.gets
      File.open(File.join(dirName, 'sep'), 'w') do |fsep|
        for i in 0...line.length do
          if delimiters.include?(line[i]) then
            fsep.print(line[i])
          end
        end
        fsep.print("\n")
      end
      loop do
        line.chomp!
        fields = line.split(splitPattern)
        for i in 0...fields.length do
          fld = fields[i]
          columnFiles[i].write("#{fld}\n")
        end
        break if not line = f.gets
      end
    end
    columnFiles.values().each {|f| f.close }
  end

  def processNameFiles(dirName)
    Dir.chdir(dirName)
    transfName = Hash.new
    Dir['*'].grep(/^[0-9]*$/) do |f|
      print "File matching [0-9]*: #{f}\n"
      fName = f
      numeric = isNumericFile(fName)
      if numeric then
        diffFile(fName)
        fName = diffName(fName)
      else
        rleFile(fName)
        fName = rleName(fName)
      end
      if File.size(fName) > 0.9 * File.size(f) then
        File.delete(fName)
        revFile(f)
        fName = reversedName(f)
      end
      transfName[f] = fName
      print "Transformed name for #{f} = #{fName}\n"
    end

    bestFiles = transfName.values
  end

  def noEOLName(fileName)
    fileName + '_noEOL'
  end
end

require 'benchmark'

def main
  _SOLEXA='-solexa'
  _LS454='-ls454'
  _SOLiD='-solid'

#  date=Time.new.strftime("%Y-%m-%d_%H:%M:%S")
#    $stdout.reopen("log/out-#{date}.txt", "w")
#    $stderr.reopen("log/err-#{date}.txt", "w")

  if ARGV.size == 0 then
    puts "Usage: ruby lfqc.rb [type] file.fastq"
    puts "Where type is one of -ls454, -solid or -solexa"
    puts "Creates archive file.fastq.lfqc"
    exit 0
  end
 
  currentDir = Dir.pwd
  print "Current Dir #{currentDir}\n"
  type = nil
  ARGV.each do |fileName|
    if (fileName.downcase == _LS454 || fileName.downcase == _SOLiD || fileName.downcase == _SOLEXA)
      type = fileName.downcase
    elsif (fileName[0] != '#')
      fileName = File.expand_path(fileName, currentDir)
      print "Compressing #{fileName}\n"
      tm = Benchmark.measure do
        storeQualNoEOL = type == _SOLEXA
        lfqc = LFQC.new(fileName, storeQualNoEOL)
        lfqc.compress
      end
      print "lfqc #{fileName} #{tm}\n"
      print "lfqcSize #{fileName} #{fileSize(fileName + '.lfqc')} uncompressed size #{fileSize(fileName)}\n"
    end
  end
end

if __FILE__ == $0
  main
end
