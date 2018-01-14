#! /usr/bin/env ruby

require 'fileutils'
require_relative './common'

def hashtag_url(tag, page)
  if page
    URI "https://www.instagram.com/explore/tags/#{tag}/?__a=1&max_id=#{page}"
  else
    URI "https://www.instagram.com/explore/tags/#{tag}/?__a=1"
  end
end

def download_hashtag_page(hashtag, page)
  hashtag_json = Common.call_api(hashtag_url(hashtag, page))
  hashtag_info = hashtag_json['graphql']['hashtag']
  size = 0
  %w(media top_posts).each do |part|
    next if part == 'top_posts' && page

    edges = hashtag_info["edge_hashtag_to_#{part}"]['edges']
    next if edges.empty?
    folder = "##{hashtag}/#{part}/"
    FileUtils.mkdir_p(folder)
    edges.each do |edge|
      node = edge['node']
      if node['is_video']
        video_json = Common.call_api(Common.video_url(node['shortcode']))
        Common.add_to_downloads(video_json['graphql']['shortcode_media']['video_url'], "#{folder}#{node['id']}.mp4")
      end
      Common.add_to_downloads(node['display_url'], "#{folder}#{node['id']}.jpg")
    end
    size += edges.size
  end

  if hashtag_info['edge_hashtag_to_media']['page_info']['has_next_page']
    [size, hashtag_info['edge_hashtag_to_media']['page_info']['end_cursor']]
  else
    [size, nil]
  end
end

def download_hashtag(hashtag, limit)
  puts "Downloading ##{hashtag}"
  next_page = nil
  size = 0
  loop do
    sze, next_page = download_hashtag_page(hashtag, next_page)
    size += sze
    puts "Downloaded #{size} on ##{hashtag}"
    break if next_page.nil? || size > limit
  end
  puts "Downloaded #{size} elements"
end

Common.initialize_downloads(8)
limit = 1000
if ARGV.empty?
  download_hashtag('cats', limit)
else
  ARGV.each do |arg|
    download_hashtag(arg, limit)
  end
end
Common.wait
