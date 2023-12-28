require 'rmagick'
require 'tempfile'
require 'fileutils'

class Resizer
  UPPER_SIZE = 10 * 1000 * 1000 # 10MB in filesystem
  def initialize(original_file_name:)
    @original_file_name = original_file_name
    @output_file_name = "#{@original_file_name}.resized.jpg"
  end

  def resize
    FileUtils.rm_f(@output_file_name)

    unless limit_over?(@original_file_name)
      FileUtils.cp(@original_file_name, @output_file_name)
    else
      lower_scale = 0.1
      upper_scale = 1.0

      image_orig = Magick::Image.read(@original_file_name).first
      tempfile = Tempfile.create(['', '.jpg'])
      image_orig.scale(lower_scale).write(tempfile.path)
      raise "Failed to resize: #{@original_file_name}" if limit_over?(tempfile.path)

      FileUtils.cp(tempfile.path, @output_file_name)

      10.times do
        scale = (lower_scale + upper_scale) / 2
        puts scale
        tempfile = Tempfile.create(['', '.jpg'])
        image_orig.scale(scale).write(tempfile.path)

        if limit_over?(tempfile.path)
          upper_scale = scale
        else
          lower_scale = scale
          FileUtils.cp(tempfile.path, @output_file_name)
        end

        FileUtils.rm(tempfile.path)
      end
    end

    original_file_size_mb = Magick::Image.read(@original_file_name).first.filesize.to_f / (1000 * 1000)
    output_file_size_mb = Magick::Image.read(@output_file_name).first.filesize.to_f / (1000 * 1000)
    puts "result | #{@original_file_name} -> #{@output_file_name}: #{'%.1f' % original_file_size_mb}MB -> #{'%.1f' % output_file_size_mb}MB"
  end

  private
  def limit_over?(file)
    image = Magick::Image.read(file).first
    filesize = image.filesize
    filesize >= UPPER_SIZE
  end
end

ARGV.each do |filename|
  Resizer.new(original_file_name: filename).resize
end
