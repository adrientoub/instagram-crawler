require 'fileutils'
require_relative './common'

def user_url(username)
  URI "https://www.instagram.com/#{username}/?__a=1"
rescue URI::InvalidURIError
  Common.error "Invalid username #{username}"
  nil
end

def user_url_paged(user_id, page)
  url = "https://www.instagram.com/graphql/query/?query_id=17888483320059182&id=#{user_id}&first=12"
  URI(if page
    url + "&after=#{page}"
  else
    url
  end)
rescue URI::InvalidURIError
  Common.error "Invalid user_id #{user_id}"
  nil
end

def download_user_page(username, user_id, page, update, use_cookie)
  user_json = Common.call_api(user_url_paged(user_id, page), use_cookie)
  return [0, nil, use_cookie] if user_json.nil?

  user_info = user_json['data']['user']['edge_owner_to_timeline_media']

  nodes = user_info['edges']
  return 0 if nodes.empty?
  folder = username + '/'
  nodes.each_with_index do |node, i|
    if !Common.download_node(node['node'], folder, nil, use_cookie) && update
      return [i, nil, use_cookie]
    end
  end

  if user_info['page_info']['has_next_page']
    [nodes.size, user_info['page_info']['end_cursor'], use_cookie]
  else
    [nodes.size, nil, use_cookie]
  end
end

def download_user_info(username)
  user_json = Common.call_api(user_url(username), false)
  if user_json.nil?
    Common.warn "Impossible to download user info for #{username}."
    return
  end

  user_info = user_json['graphql']['user']
  Common.info "Found #{user_info['edge_owner_to_timeline_media']['count']} media for #{username}."

  folder = username + '/'
  FileUtils.mkdir_p(folder)
  Common.add_to_downloads(user_info['profile_pic_url_hd'], "#{folder}profile.jpg", nil)
  if user_info['is_private']
    Common.warn "This user is \e[31mprivate\e[0m"
    [user_info['id'], true]
  else
    [user_info['id'], false]
  end
end

def update_user(username)
  Common.info "Updating #{username}"
  next_page = nil
  size = 0
  user_id, use_cookie = download_user_info(username)

  loop do
    sze, next_page, use_cookie = download_user_page(username, user_id, next_page, true, use_cookie)
    size += sze
    Common.info "Queued #{size} media for #{username}."
    break if next_page.nil?
  end
end

def download_user(username)
  Common.info "Downloading #{username}"
  next_page = nil
  size = 0
  user_id, use_cookie = download_user_info(username)

  loop do
    sze, next_page, use_cookie = download_user_page(username, user_id, next_page, false, use_cookie)
    size += sze
    Common.info "Queued #{size} media for #{username}."
    break if next_page.nil?
  end
end
