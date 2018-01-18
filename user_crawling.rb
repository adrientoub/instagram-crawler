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
  if page.nil?
    Common.info "Found #{user_info['media']['count']} media for #{username}."
  end
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
    Common.download_node(node, folder)
  end

  if user_info['media']['page_info']['has_next_page']
    [nodes.size, user_info['media']['page_info']['end_cursor']]
  else
    [nodes.size, nil]
  end
end

def download_user(username)
  Common.info "Downloading #{username}"
  next_page = nil
  size = 0
  loop do
    sze, next_page = download_user_page(username, next_page)
    size += sze
    Common.info "Queued #{size} media for #{username}."
    break if next_page.nil?
  end
end
