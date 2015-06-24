require 'pathname'
require 'securerandom'
require 'fileutils'

require_relative 'utils.rb'
require_relative 'CompressionMethod.rb'
require_relative 'LPAQCompressionMethod.rb'
require_relative 'ZPAQCompressionMethod.rb'

$compMethods = Hash.new
$compMethods["lpaq"] = LPAQCompressionMethod.new
$compMethods["zpaq"] = ZPAQCompressionMethod.new

class LFQCD
  def decompress(filePath, uncompFilePath)
    @filePath = filePath
    pn = Pathname.new(filePath)
    @zipFileName = pn.basename.to_s
    @fileName = uncompFilePath
    @fileDir = pn.dirname
    @workDir  = File.join(@fileDir, 'tmp_' + SecureRandom.hex()  + '_' + @zipFileName)
    print "Work dir #{@workDir}\n"

    FileUtils.mkdir_p(@workDir)
    Dir.chdir(@workDir)
    untarAll()
    nameArchive = Dir["*_name*"][0]
    dataArchive = File.join(@workDir, Dir["*_data*"][0])
    qualArchive = File.join(@workDir, Dir["*_qual*"][0])

    threadData = Thread.new do
      print "Unzipping data file #{dataArchive}\n"
      dataFile = unzipFile(dataArchive)
      File.delete(dataArchive)
      dataFile
    end
    
    threadQual = Thread.new do
      Dir.chdir(@workDir) do
        print "Unzipping qual file #{qualArchive}\n"
        qualFile = unzipFile(qualArchive)
        File.delete(qualArchive)
        qualFile
      end
    end

    # wait for quality score decompression to complete
    qualFile = threadQual.value
    
    nameDir = 'nameDir'
    FileUtils.mkdir_p(nameDir)
    FileUtils.mv(nameArchive, nameDir)
    Dir.chdir(nameDir)
    unzipFile(nameArchive)
    File.delete(nameArchive)
    processNameFiles
    maxColumn = Dir['*'].grep(/^[0-9]*$/).map(&:to_i).max
    columnSeparator = File.read('sep') #['.',' ',' ','=',"\n"]
    nameFile = File.join(@workDir, File.basename(nameArchive, '.*'))
    mergeNameFields(maxColumn,columnSeparator, nameFile)

    # wait for DNA decompression to complete
    dataFile = threadData.value
    
    Dir.chdir(@workDir)
    unsplitFastq(nameFile, dataFile, qualFile, @fileName)
    print "Cleaning up...\n"
    cleanUp()
    print "Done.\n"
    @fileName
  end

  def untarAll
    cmd = "tar xf #{@filePath} -C #{@workDir}"
    print "Running #{cmd}\n"
    system(cmd)
  end

  def unzipFile(fileName)
    extension = File.extname(fileName)
    comp = if extension == '.lpaq' then
      $compMethods['lpaq']
    elsif  extension == '.zpaq' then
      $compMethods['zpaq']
    else
      raise "Unknown archive with extension #{extension}!"
      nil
    end
    comp.unzip(fileName)
    comp.unzippedName(fileName)
  end

  def processNameFiles()
    transfName = Hash.new
    Dir['*'].grep(/^[0-9]*_.*$/) do |f|
      print "Processing file #{f}\n"
      if isDiffFile(f) then
        undiffFile(f)
      elsif isRleFile(f) then
        unrleFile(f)
      elsif isRevFile(f) then
        unrevFile(f)
      else
        $stderr.print "Unrecognized file #{f}! Ignoring.\n"
      end
      #     File.delete(f)
    end
  end

  def mergeNameFields(maxColumn, columnSeparator, outputFile)
    columnFiles = []
    for i in 0..maxColumn do
      columnFiles.push(File.open(i.to_s, 'r'))
    end

    print "Max Column #{maxColumn}\n"
    File.open(outputFile,'w') do |f|
      loop do
        ok = false
        out = ''
        for i in 0..maxColumn do
          line = columnFiles[i].gets
          if line != nil then
            out += line.chomp + columnSeparator[i]
            f.print(line.chomp)
            f.print(columnSeparator[i])
            ok = true
          end
        end
        break if not ok
      end
    end
  end

  def unsplitFastq(nameFile, dataFile, qualFile, outputFile)
    File.open(qualFile, 'r') do |fqual|
      if qualFile.end_with?('_noEOL') then
        storeQualNoEOL = true
        readLen = fqual.gets.chomp.to_i
      else
        storeQualNoEOL = false
      end
      File.open(nameFile, 'r') do |fname|
        File.open(dataFile, 'r') do |fdata|
          File.open(outputFile,'w') do |fout|
            loop do
              # sequence name
              break if not line = fname.gets
              fout.write(line)

              # quality score
              if (storeQualNoEOL)
                break if not qual = fqual.gets(readLen)
              else
                break if not qual = fqual.gets
                qual.chomp!
                readLen = qual.length
              end

              # dna
              break if not data = fdata.gets(readLen)
              fout.write("#{data}\n+\n#{qual}\n")
            end
          end
        end
      end
    end
  end

  def cleanUp
    cmd = "rm -rf #{@workDir}"
    system(cmd)
  end
end

require 'benchmark'


#date=Time.new.strftime("%Y-%m-%d_%H:%M:%S")
#$stdout.reopen("log/out-#{date}.txt", "w")
#$stderr.reopen("log/err-#{date}.txt", "w")

def maind
  currentDir = Dir.pwd
  if ARGV.length == 0 then
     print "Arguments: inputFile.lfqc [outputFile]\n"
     exit 0
  end

  fileName = ARGV[0]
  fileName = File.expand_path(fileName, currentDir)
  pn = Pathname.new(fileName)
  fileDir = pn.dirname
  if ARGV.length > 1 then
    uncompFileName = ARGV[1]
    uncompFileName = File.expand_path(uncompFileName, currentDir).to_s
  else
    uncompFileName = pn.basename('.lfqc').to_s
    uncompFileName = File.expand_path(uncompFileName, fileDir).to_s
  end
  if File.exist?(uncompFileName) then
    print "Error: output file #{uncompFileName} already exists!\n"
    exit
  end

  tm = Benchmark.measure do
    uncompFileName = LFQCD.new.decompress(fileName, uncompFileName)
  end
  print "lfqcd #{fileName} #{tm}\n"
  print "lfqcdSize #{uncompFileName} #{fileSize(uncompFileName)} compressed size #{fileSize(fileName)}\n"
end

if __FILE__ == $0
  maind
end
