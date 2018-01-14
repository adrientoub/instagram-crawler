#! /usr/bin/env ruby

require 'net/http'
require 'json'
require 'fileutils'
require 'logger'

def user_url(tag, page)
  if page
    URI "https://www.instagram.com/#{tag}/?__a=1&max_id=#{page}"
  else
    URI "https://www.instagram.com/#{tag}/?__a=1"
  end
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

def add_to_downloads(uri, path = nil)
  to_add = if path.nil?
    uri
  else
    [{
      uri: uri,
      path: path
    }]
  end
  $semaphore.synchronize do
    $downloads += to_add
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
  begin
    user_call = download(user_url(username, page))
    user_json = JSON.parse(user_call)
  rescue
    $logger.warn "Download failed, retrying"
    sleep 1
    retry
  end

  user_info = user_json['user']
  folder = username + '/'
  FileUtils.mkdir_p(folder)
  add_to_downloads(URI(user_info['profile_pic_url_hd']), "#{folder}profile.jpg")
  if user_info['is_private']
    puts 'This user is private'
  end
  nodes = user_info['media']['nodes']
  return 0 if nodes.empty?
  size = nodes.size
  add_to_downloads(nodes.map do |node|
    {
      uri: URI(node['display_src']),
      path: "#{folder}#{node['id']}.jpg"
    }
  end)

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
