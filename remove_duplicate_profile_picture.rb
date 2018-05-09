#! /usr/bin/env ruby
require 'fileutils'
require 'digest'
require 'logger'

logger = Logger.new(STDOUT)
rm_count = 0

FileUtils.mkdir('#to_rm') unless File.exists?('#to_rm')
Dir.new('.').each do |filename|
  next unless File.directory?(filename)

  list = Dir.glob("#{filename}/profile*.jpg")
  h = {}
  list.each do |path|
    hash = Digest::SHA256.file(path).hexdigest
    h[hash] ||= []
    h[hash] << path
  end

  h.each do |hash, files|
    # if there are duplicates
    if files.size > 1
      logger.warn "Found #{files.join('; ')} with the same hash (#{hash})"
      files.sort[1..-1].each do |file|
        rm_count += 1
        # FileUtils.rm(file)
        FileUtils.mv(file, '#to_rm/' + file.gsub('/', '-'))
        logger.warn "Removing #{file}"
      end
    end
  end
end

logger.warn "Removed #{rm_count} files"
