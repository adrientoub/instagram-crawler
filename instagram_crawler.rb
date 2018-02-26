#! /usr/bin/env ruby

require './hashtag_crawling'
require './user_crawling'
require './update'

LIMIT = ENV['LIMIT']&.to_i || 1000

def print_usage
  $stderr.puts 'Usage: ./instagram_crawler.rb [USERNAME...] [#HASHTAG...]'
  $stderr.puts '                              [--update] [--update-users] [--update-hashtags]'
  exit(1)
end

Common.initialize_downloads(8)
if ARGV.empty?
  print_usage
else
  ARGV.each do |arg|
    if arg[0] == '#'
      download_hashtag(arg[1..-1], LIMIT)
    elsif arg == '--update'
      update(LIMIT)
    elsif arg == '--update-hashtags'
      update_hashtags(LIMIT)
    elsif arg == '--update-users'
      update_users
    elsif arg == '--help' || arg == '-h'
      print_usage
    elsif arg[0] == '-'
      $stderr.puts "Unknown option #{arg}."
      print_usage
    else
      download_user(arg)
    end
  end
end
Common.wait
