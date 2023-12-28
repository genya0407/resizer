require 'rmagick'
require 'tempfile'
require 'fileutils'

ORIGINAL_FILE_NAME = ARGV[0]
OUTPUT_FILE_NAME = "#{ORIGINAL_FILE_NAME}.resized.jpg"
UPPER_SIZE = 10 * 1024 * 1024 # 10MB

def should_update?(file)
  new_filesize = Magick::Image.read(file).first.filesize
  return false if new_filesize > UPPER_SIZE
  return true unless File.exists?(OUTPUT_FILE_NAME)

  output_filesize = Magick::Image.read(OUTPUT_FILE_NAME).first.filesize
  return true if new_filesize > output_filesize

  false
end

image_orig = Magick::Image.read(ORIGINAL_FILE_NAME).first
scale = 0.5
3.times do
  tempfile = Tempfile.create(['', '.jpg'])
  image_orig.scale(scale).write(tempfile.path)
  if should_update?(tempfile.path)
    FileUtils.cp(tempfile.path, OUTPUT_FILE_NAME)
    scale = (1.0 + scale) / 2
  else
    scale = scale / 2
  end
  FileUtils.rm(tempfile.path)
end

