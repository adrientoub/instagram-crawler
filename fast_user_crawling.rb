#! /usr/bin/env ruby

require 'net/http'
require 'json'
require 'fileutils'
require 'logger'

def user_url(username, page)
  if page
    URI "https://www.instagram.com/#{username}/?__a=1&max_id=#{page}"
  else
    URI "https://www.instagram.com/#{username}/?__a=1"
  end
end

def video_url(code)
  URI "https://www.instagram.com/p/#{code}/?__a=1"
end

def download(uri, try = 3)
  response = Net::HTTP.get_response uri
  if response.code.to_i >= 399
    if try > 0
      $logger.puts "Downloading #{uri} ended in #{response.code}. Retrying #{try} times."
      download(uri, try - 1)
    else
      response.body
    end
  else
    response.body
  end
end

def download_to_file(uri, path)
  return if File.exist?(path)
  File.open(path, 'wb') do |file|
    file.write download(uri)
  end
end

def call_api(uri)
  begin
    user_call = download(uri)
    JSON.parse(user_call)
  rescue => e
    $logger.warn "Download failed (#{e}) retrying"
    sleep 1
    retry
  end
end

def add_to_downloads(url, path)
  obj = {
    uri: URI(url),
    path: path
  }

  $semaphore.synchronize do
    $downloads << obj
  end
end

def initialize_downloads(thread_count)
  $semaphore = Mutex.new
  $logger = Logger.new(STDOUT)
  $downloads = []
  $done = false
  $threads = []

  thread_count.times do
    $threads << Thread.new do
      loop do
        download = $semaphore.synchronize do
          $downloads.pop
        end
        if download.nil?
          break if $done
          sleep 0.05
          next
        end
        download_to_file(download[:uri], download[:path])
      end
    end
  end
end

def wait
  $threads.each(&:join)
end

def download_user_page(username, page = nil)
  user_json = call_api(user_url(username, page))

  user_info = user_json['user']
  folder = username + '/'
  FileUtils.mkdir_p(folder)
  add_to_downloads(user_info['profile_pic_url_hd'], "#{folder}profile.jpg")
  if user_info['is_private']
    puts 'This user is private'
  end
  nodes = user_info['media']['nodes']
  return 0 if nodes.empty?
  size = nodes.size
  nodes.each do |node|
    if node['__typename'] == 'GraphVideo'
      video_json = call_api(video_url(node['code']))
      add_to_downloads(video_json['graphql']['shortcode_media']['video_url'], "#{folder}#{node['id']}.mp4")
    end
    add_to_downloads(node['display_src'], "#{folder}#{node['id']}.jpg")
  end

  if user_info['media']['page_info']['has_next_page']
    [size, user_info['media']['page_info']['end_cursor']]
  else
    [size, nil]
  end
end

def download_user(username)
  puts "Downloading #{username}"
  next_page = nil
  size = 0
  loop do
    sze, next_page = download_user_page(username, next_page)
    size += sze
    break if next_page.nil?
  end
  puts "Downloaded #{size} elements"
end

initialize_downloads(8)
start = Time.now
if ARGV.empty?
  download_user('adrientoub')
else
  ARGV.each do |arg|
    download_user(arg)
  end
end
$done = true
wait
puts "Done in #{Time.now - start}s"
