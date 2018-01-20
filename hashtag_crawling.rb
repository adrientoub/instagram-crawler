require 'fileutils'
require_relative './common'

def hashtag_url(tag, page)
  if page
    URI "https://www.instagram.com/explore/tags/#{tag}/?__a=1&max_id=#{page}"
  else
    URI "https://www.instagram.com/explore/tags/#{tag}/?__a=1"
  end
rescue URI::InvalidURIError
  Common.error "Invalid hashtag ##{tag}"
  nil
end

def download_hashtag_page(hashtag, page)
  hashtag_json = Common.call_api(hashtag_url(hashtag, page))
  return [0, nil] if hashtag_json.nil?
  hashtag_info = hashtag_json['graphql']['hashtag']
  size = 0
  %w(media top_posts).each do |part|
    next if part == 'top_posts' && page

    edges = hashtag_info["edge_hashtag_to_#{part}"]['edges']
    next if edges.empty?
    folder = "##{hashtag}/#{part}/"
    FileUtils.mkdir_p(folder)
    edges.each do |edge|
      Common.download_node(edge['node'], folder)
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
  Common.info "Queuing ##{hashtag}"
  next_page = nil
  size = 0
  loop do
    sze, next_page = download_hashtag_page(hashtag, next_page)
    size += sze
    Common.info "Queued #{size} media for ##{hashtag}."
    break if next_page.nil? || size > limit
  end
end
