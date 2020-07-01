require 'fileutils'
require 'nokogiri'
require 'date'
require 'digest'
require_relative './common'

def user_url(username)
  URI "https://www.instagram.com/#{username}/"
rescue URI::InvalidURIError
  Common.error "Invalid username #{username}"
  nil
end

def variables(user_id, end_cursor)
  vars = "{\"id\":\"#{user_id}\",\"first\":12,\"after\":\"#{end_cursor}\"}"
end

def next_page_url(vars)
  URI "https://www.instagram.com/graphql/query/?query_hash=42323d64886122307be10013ad2dcc44&variables=#{vars}"
end

def download_user_info(username)
  user_html = Common.download(user_url(username), false)
  parsed_html = Nokogiri::HTML(user_html)
  user_json = nil
  parsed_html.css('script').each do |script|
    user_json = script.content if script.content =~ /window._sharedData =/
  end
  if user_json.nil?
    Common.warn "Impossible to download user info for #{username}."
    return
  end

  user_json = user_json.sub('window._sharedData = ', '')[0..-2]
  parsed = JSON.parse(user_json)
  if parsed['entry_data'].empty?
    Common.warn "The user #{username} doesn't exist."
    return
  end
  user_info = parsed.dig('entry_data', 'ProfilePage', 0, 'graphql', 'user')
  if user_info.nil?
    Common.warn "Error retrieving info about user #{username}."
    return
  end
  Common.info "Found #{user_info['edge_owner_to_timeline_media']['count']} media for #{username}."

  folder = username + '/'
  FileUtils.mkdir_p(folder)
  Common.add_to_downloads(user_info['profile_pic_url_hd'], "#{folder}profile_#{Date.today.to_s}.jpg", nil)
  if user_info['is_private']
    Common.warn "This user is \e[31mprivate\e[0m"
    [user_info['id'], true]
  else
    nodes = user_info['edge_owner_to_timeline_media']['edges']
    nodes.each do |node|
      Common.download_node(node['node'], folder, nil, false)
    end

    page_info = user_info['edge_owner_to_timeline_media']['page_info']
    [user_info['id'], page_info['has_next_page'], page_info['end_cursor'], parsed['rhx_gis']]
  end
end

def download_user_media(user_id, end_cursor, username, gis)
  vars = variables(user_id, end_cursor)

  new_gis = Digest::MD5.hexdigest("#{gis}:#{vars}")

  medias = Common.call_api(next_page_url(vars), false, { user: username, gis: new_gis })
  user = medias['data']['user']

  folder = username + '/'

  nodes = user['edge_owner_to_timeline_media']['edges']
  nodes.each do |node|
    Common.download_node(node['node'], folder, nil, false)
  end
  page_info = user['edge_owner_to_timeline_media']['page_info']

  [page_info['has_next_page'], page_info['end_cursor']]
end

def download_user(username, update = false)
  Common.info "Downloading #{username}"
  next_page = nil

  user_id, has_next_page, end_cursor, gis = download_user_info(username)
  return if update
  size = 12

  while has_next_page
    size += 12
    has_next_page, end_cursor = download_user_media(user_id, end_cursor, username, gis)
    Common.info "Queued #{size} media for #{username}."
  end
end
