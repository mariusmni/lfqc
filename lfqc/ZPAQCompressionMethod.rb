class ZPAQCompressionMethod
  include CompressionMethod
  def extension
    '.zpaq'
  end

  def getExePath
    File.join(File.dirname(__FILE__), '../zpaq702/zpaq').to_s
  end
  
  def getArchiveCmd(zName, fileName)
    zpaq = getExePath()
    "#{zpaq} a #{zName} #{fileName} -method 5 -threads 4"
  end
  
  def getUnzipCmd(zName)
    zpaq = getExePath()
    "#{zpaq} e #{zName} -threads 4"
  end
end