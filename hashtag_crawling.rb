#! /usr/bin/env ruby

require 'net/http'
require 'json'
require 'parallel'
require 'fileutils'

def hashtag_url(tag)
  URI "https://www.instagram.com/explore/tags/#{tag}/?__a=1"
end

def download(uri)
  Net::HTTP.get uri
end

def download_to_file(uri, path)
  return if File.exist?(path)
  File.open(path, 'wb') do |file|
    file.write download(uri)
  end
end

def download_hashtag(hashtag)
  puts "Downloading ##{hashtag}"
  hashtag_call = download(hashtag_url(hashtag))
  hashtag_json = JSON.parse(hashtag_call)
  hashtag_info = hashtag_json['graphql']['hashtag']
  %w(media top_posts).each do |part|
    edges = hashtag_info["edge_hashtag_to_#{part}"]['edges']
    next if edges.empty?
    folder = "##{hashtag}/#{part}/"
    puts "Downloading ##{hashtag} #{part}"
    FileUtils.mkdir_p(folder)
    Parallel.each(edges, in_threads: 8) do |edge|
      download_to_file(URI(edge['node']['display_url']), "#{folder}#{edge['node']['id']}.jpg")
    end
  end
end

if ARGV.empty?
  download_hashtag('cats')
else
  ARGV.each do |arg|
    download_hashtag(arg)
  end
end
