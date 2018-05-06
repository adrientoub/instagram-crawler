require 'net/http'
require 'logger'
require 'json'

class Common
  def self.call_api(uri, use_cookie = false)
    return if uri.nil?

    user_call = download(uri, use_cookie)
    JSON.parse(user_call)
  rescue JSON::ParserError => e
    @logger.warn "JSON parsing failed for URI: #{uri}, not retrying."
    nil
  rescue => e
    @logger.warn "Download failed for URI: #{uri} (#{e}) retrying"
    sleep 1
    retry
  end

  def self.video_url(code)
    URI "https://www.instagram.com/p/#{code}/?__a=1"
  end

  def self.add_to_downloads(url, path, timestamp)
    return false if File.exist?(path) && !@force
    if timestamp
      timestamp = Time.at(timestamp)
    end
    obj = {
      uri: URI(url),
      path: path,
      time: timestamp
    }

    @semaphore.synchronize do
      @downloads << obj
    end
    true
  end

  def self.initialize_downloads(thread_count)
    @start = Time.now
    @semaphore = Mutex.new
    @logger = Logger.new(STDOUT)
    @downloads = []
    @done = false
    @threads = []
    @force = false

    thread_count.times do
      @threads << Thread.new do
        loop do
          download = @semaphore.synchronize do
            @downloads.pop
          end
          if download.nil?
            break if @done
            sleep 0.05
            next
          end
          download_to_file(download[:uri], download[:path], download[:time])
        end
      end
    end
  end

  def self.wait
    @done = true
    @threads.each(&:join)
    Common.info "Done in #{Time.now - @start}s"
  end

  def self.video_url(code)
    URI "https://www.instagram.com/p/#{code}/?__a=1"
  end

  def self.download_image(node, folder, timestamp)
    timestamp ||= node['taken_at_timestamp'] || node['date']
    Common.add_to_downloads(node['display_src'] || node['display_url'], "#{folder}#{node['id']}.jpg", timestamp)
  end

  def self.download_node(node, folder, timestamp, use_cookie)
    if node['__typename'] == 'GraphSidecar'
      sidecar_json = Common.call_api(Common.video_url(node['code'] || node['shortcode']), use_cookie)
      unless sidecar_json.nil?
        media = sidecar_json['graphql']['shortcode_media']
        timestamp ||= media['taken_at_timestamp'] || media['date']
        sidecar_json['graphql']['shortcode_media']['edge_sidecar_to_children']['edges'].each do |edge|
          download_node(edge['node'], folder, timestamp, use_cookie)
        end
      end
    elsif node['__typename'] == 'GraphVideo' || node['is_video']
      if node['video_url']
        Common.add_to_downloads(node['video_url'], "#{folder}#{node['id']}.mp4", timestamp)
      else
        video_json = Common.call_api(Common.video_url(node['code'] || node['shortcode']), use_cookie)
        unless video_json.nil?
          media = video_json['graphql']['shortcode_media']
          timestamp ||= media['taken_at_timestamp'] || media['date']
          Common.add_to_downloads(media['video_url'], "#{folder}#{node['id']}.mp4", timestamp)
        end
      end
      download_image(node, folder, timestamp)
    else
      download_image(node, folder, timestamp)
    end
  end

  def self.info(str)
    @logger.info str
  end

  def self.error(str)
    @logger.error str
  end

  def self.warn(str)
    @logger.warn str
  end

  private

  def self.download(uri, use_cookie = false, try = 3, first = true)
    response = if ENV['COOKIE'] && use_cookie
      http = Net::HTTP.new(uri.hostname, uri.port)
      http.use_ssl = true
      http.get(uri, 'Cookie' => ENV['COOKIE'])
    else
      Net::HTTP.get_response uri
    end

    if response.code.to_i >= 399
      if try > 0
        @logger.warn "Downloading #{uri} ended in #{response.code}. Retrying #{try} times."
        if response.code.to_i == 429
          sleep 7
          return download(uri, use_cookie, 20, false) if first
        else
          sleep 1
        end
        download(uri, use_cookie, try - 1, first)
      else
        response.body
      end
    else
      response.body
    end
  rescue => e
    if try > 0
      @logger.warn "Downloading #{uri} ended in #{e}. Retrying #{try} times."
      sleep 1
      download(uri, use_cookie, try - 1, first)
    else
      ""
    end
  end

  def self.download_to_file(uri, path, time)
    File.open(path, 'wb') do |file|
      file.write download(uri)
    end
    File.utime(time, time, path) if time
  end
end
