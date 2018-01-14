#! /usr/bin/env ruby

require './hashtag_crawling'
require './user_crawling'

LIMIT = 1000

Common.initialize_downloads(8)
if ARGV.empty?
  download_user('adrientoub')
else
  ARGV.each do |arg|
    if arg[0] == '#'
      download_hashtag(arg[1..-1], LIMIT)
    else
      download_user(arg)
    end
  end
end
Common.wait
