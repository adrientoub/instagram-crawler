require 'fileutils'
require 'nokogiri'
require 'date'
require_relative './common'

def user_url(username)
  URI "https://www.instagram.com/#{username}/"
rescue URI::InvalidURIError
  Common.error "Invalid username #{username}"
  nil
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
  user_info = parsed['entry_data']['ProfilePage'].first['graphql']['user']
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

    [user_info['id'], false]
  end
end

def download_user(username)
  Common.info "Downloading #{username}"
  next_page = nil
  size = 0
  download_user_info(username)
end
