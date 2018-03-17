require 'fileutils'
require_relative './common'

def user_url(username, page)
  if page
    URI "https://www.instagram.com/#{username}/?__a=1&max_id=#{page}"
  else
    URI "https://www.instagram.com/#{username}/?__a=1"
  end
rescue URI::InvalidURIError
  Common.error "Invalid username #{username}"
  nil
end

def download_user_page(username, page, update, use_cookie)
  user_json = Common.call_api(user_url(username, page), use_cookie)
  return [0, nil, use_cookie] if user_json.nil?

  user_info = user_json['graphql']['user']
  folder = username + '/'
  FileUtils.mkdir_p(folder)
  Common.add_to_downloads(user_info['profile_pic_url_hd'], "#{folder}profile.jpg", nil)
  if user_info['is_private']
    unless use_cookie
      Common.warn "This user is \e[31mprivate\e[0m"
      return download_user_page(username, page, update, true)
    end
  end

  if page.nil?
    Common.info "Found #{user_info['edge_owner_to_timeline_media']['count']} media for #{username}."
  end
  nodes = user_info['edge_owner_to_timeline_media']['edges']
  return 0 if nodes.empty?
  size = nodes.size
  nodes.each_with_index do |node, i|
    if !Common.download_node(node['node'], folder, nil, use_cookie) && update
      return [i, nil, use_cookie]
    end
  end

  if user_info['edge_owner_to_timeline_media']['page_info']['has_next_page']
    [nodes.size, user_info['edge_owner_to_timeline_media']['page_info']['end_cursor'], use_cookie]
  else
    [nodes.size, nil, use_cookie]
  end
end

def update_user(username)
  Common.info "Updating #{username}"
  next_page = nil
  size = 0
  use_cookie = false
  loop do
    sze, next_page, use_cookie = download_user_page(username, next_page, true, use_cookie)
    size += sze
    Common.info "Queued #{size} media for #{username}."
    break if next_page.nil?
  end
end


def download_user(username)
  Common.info "Downloading #{username}"
  next_page = nil
  size = 0
  use_cookie = false
  loop do
    sze, next_page, use_cookie = download_user_page(username, next_page, false, use_cookie)
    size += sze
    Common.info "Queued #{size} media for #{username}."
    break if next_page.nil?
  end
end
