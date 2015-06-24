module CompressionMethod
  def zippedName(fileName)
    fileName + extension
  end

  def unzippedName(zName)
    zName.chomp(extension)
  end

  def archive2(zName, fileName)
    cmd = getArchiveCmd(zName, fileName)
    if cmd != nil then
      if File.exist?(zName)
        File.delete(zName)
      end
      print "Running #{cmd}\n"
      system(cmd)
    end
  end

  def archive(fileName)
    zName = zippedName(fileName)
    archive2(zName, fileName)
  end

  def extract(zName)
    unzip(zName)
  end
  
  def unzip(zName)
    cmd = getUnzipCmd(zName)
    if cmd != nil then
      print "Running #{cmd}\n"
      system(cmd)
    end
  end
end