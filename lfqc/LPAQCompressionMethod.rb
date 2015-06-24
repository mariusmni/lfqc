class LPAQCompressionMethod
  include CompressionMethod

  def extension
    '.lpaq'
  end
  
  def getExePath
    File.join(File.dirname(__FILE__), '../lpaq8/lpaq8').to_s
  end

  def getArchiveCmd(zName, fileName)
    lpaq8 = getExePath()
    "#{lpaq8} 9 #{fileName}  #{zName}"
  end

  def getUnzipCmd(zName)
    fileName = unzippedName(zName)
    lpaq8 = getExePath()
    "#{lpaq8} d #{zName} #{fileName}"
  end
end