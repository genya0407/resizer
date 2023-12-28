require 'rmagick'
require 'tempfile'
require 'fileutils'

class Resizer
  UPPER_SIZE = 10 * 1024 * 1024 # 10MB
  def initialize(original_file_name:)
    @original_file_name = original_file_name
    @output_file_name = "#{@original_file_name}.resized.jpg"
  end

  def resize
    if should_update?(@original_file_name)
      FileUtils.cp(@original_file_name, @output_file_name)
    else
      image_orig = Magick::Image.read(@original_file_name).first
      scale = 0.5
      5.times do
        tempfile = Tempfile.create(['', '.jpg'])
        image_orig.scale(scale).write(tempfile.path)
        if should_update?(tempfile.path)
          FileUtils.cp(tempfile.path, @output_file_name)
          scale = (1.0 + scale) / 2
        else
          scale = scale / 2
        end
        FileUtils.rm(tempfile.path)
      end
    end

    original_file_size_mb = Magick::Image.read(@original_file_name).first.filesize.to_f / (1024 * 1024)
    output_file_size_mb = Magick::Image.read(@output_file_name).first.filesize.to_f / (1024 * 1024)
    puts "#{@original_file_name} -> #{@output_file_name}: #{'%.1f' % original_file_size_mb}MB -> #{'%.1f' % output_file_size_mb}MB"
  end

  private
  def should_update?(file)
    new_filesize = Magick::Image.read(file).first.filesize
    return false if new_filesize > UPPER_SIZE
    return true unless File.exists?(@output_file_name)

    output_filesize = Magick::Image.read(@output_file_name).first.filesize
    return true if new_filesize > output_filesize

    false
  end
end

ARGV.each do |filename|
  Resizer.new(original_file_name: filename).resize
end
