require 'fileutils'
require_relative './common'

def user_url(username, page)
  if page
    URI "https://www.instagram.com/#{username}/?__a=1&max_id=#{page}"
  else
    URI "https://www.instagram.com/#{username}/?__a=1"
  end
end

def download_user_page(username, page = nil)
  user_json = Common.call_api(user_url(username, page))

  user_info = user_json['user']
  folder = username + '/'
  FileUtils.mkdir_p(folder)
  Common.add_to_downloads(user_info['profile_pic_url_hd'], "#{folder}profile.jpg")
  if user_info['is_private']
    puts 'This user is private'
  end
  nodes = user_info['media']['nodes']
  return 0 if nodes.empty?
  size = nodes.size
  nodes.each do |node|
    if node['__typename'] == 'GraphVideo'
      video_json = Common.call_api(video_url(node['code']))
      Common.add_to_downloads(video_json['graphql']['shortcode_media']['video_url'], "#{folder}#{node['id']}.mp4")
    end
    Common.add_to_downloads(node['display_src'], "#{folder}#{node['id']}.jpg")
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
