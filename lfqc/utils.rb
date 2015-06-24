$csToDNAMap = {
  'A' => { '0' => 'A', '1' => 'C', '2' => 'G', '3' => 'T', '4' => 'N'},
  'C' => { '0' => 'C', '1' => 'A', '2' => 'T', '3' => 'G', '4' => 'N'},
  'G' => { '0' => 'G', '1' => 'T', '2' => 'A', '3' => 'C', '4' => 'N'},
  'T' => { '0' => 'T', '1' => 'G', '2' => 'C', '3' => 'A', '4' => 'N'},
  'N' => { '0' => 'A', '1' => 'C', '2' => 'G', '3' => 'T', '4' => 'N'},
  ''  => { '0' => 'A', '1' => 'C', '2' => 'G', '3' => 'T', '4' => 'N'},
}

$dnaToCsMap = Hash[ $csToDNAMap.map { |k, h| [k, h.invert] } ]

def dnaToColorSpace(str)
  res = [str[0]]
  for i in 1...str.length do
    res.push($dnaToCsMap[str[i-1]][str[i]])
  end
  res.join()
end

def colorSpaceToDNA(str)
  prev = str[0]
  res = [prev]
  for i in 1...str.length do
    prev = $csToDNAMap[prev][str[i]]
    res.push(prev)
  end
  res.join()
end

def isNumericFile(fileName)
  File.open(fileName, "r") { |fin| isNumeric(fin) }
end

def isNumeric(file)
  if line = file.gets then
    line.chomp!
    line.to_i.to_s == line
  else
    false
  end
end

def rleName(fileName)
  fileName + '_rle'
end

def isRleFile(fileName)
  fileName.end_with?('_rle')
end

def unrleName(fileName)
  fileName.chomp('_rle')
end

def rleFile(fileName, foutName = rleName(fileName))
  File.open(fileName, 'r') do |fin|
    File.open(foutName, 'w') do |fout|
      rle(fin, fout)
    end
  end
end

def rle(file = $stdin, fout = $stdout)
  if (prev = file.gets) then
    fout.print prev
    count = 0
    loop do
      break if not line = file.gets
      if prev == line then
        count += 1
      else
        fout.print "#{count}\n"
        fout.print line
        count = 0
      end
      prev = line
    end
    fout.print "#{count}\n"
  end
end

def unrleFile(fileName, foutName = unrleName(fileName))
  File.open(fileName, 'r') do |fin|
    File.open(foutName, 'w') do |fout|
      unrle(fin, fout)
    end
  end
end

def unrle(file = $stdin, fout = $stdout)
  loop do
    break if not item = file.gets
    break if not countLine = file.gets
    count = countLine.chomp.to_i
    for i in 0..count do
      fout.print item
    end
  end
end

def diffName(fileName)
  fileName + '_dif'
end

def diffFile(fileName, foutName = diffName(fileName))
  File.open(fileName, 'r') do |fin|
    File.open(foutName, 'w') do |fout|
      diff(fin, fout)
    end
  end
end

def diff(file = $stdin, fout = $stdout)
  if (prev = file.gets) then
    prev = prev.to_i
    fout.print "#{prev}\n"
    loop do
      break if not line = file.gets
      n = line.to_i
      fout.print "#{n-prev}\n"
      prev = n
    end
  end
end

def isDiffFile(fileName)
  fileName.end_with?('_dif')
end

def undiffName(fileName)
  fileName.chomp('_dif')
end

def undiffFile(fileName, foutName = undiffName(fileName))
  File.open(fileName, 'r') do |fin|
    File.open(foutName, 'w') do |fout|
      undiff(fin, fout)
    end
  end
end

def undiff(file = $stdin, fout = $stdout)
  if (prev = file.gets) then
    prev = prev.to_i
    fout.print "#{prev}\n"
    loop do
      break if not line = file.gets
      d = line.to_i
      prev += d
      fout.print "#{prev}\n"
    end
  end
end

def isRevFile(fileName)
  fileName.end_with?('_rev')
end

def unrevName(fileName)
  fileName.chomp('_rev')
end

def reversedName(fileName)
  fileName + '_rev'
end

def revFile(fileName, foutName = reversedName(fileName))
  File.open(fileName,'r') do |fin|
    File.open(foutName,'w') do |fout|
      rev(fin, fout)
    end
  end
end

def rev(fin=$stdin, fout=$stdout)
  loop do
    break if not line = fin.gets
    line.chomp!
    fout.write(line.reverse + "\n")
  end
end

def unrevFile(fileName, foutName = unrevName(fileName))
  File.open(fileName,'r') do |fin|
    File.open(foutName,'w') do |fout|
      unrev(fin, fout)
    end
  end
end

def unrev(fin=$stdin, fout=$stdout)
  rev(fin, fout)
end

def fileSize(fileName)
  if File.exist?(fileName) then
    File.size(fileName)
  else
    100000000000 # large value
  end
end

