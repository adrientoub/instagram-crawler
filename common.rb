require 'net/http'
require 'logger'

class Common
  def self.call_api(uri)
    begin
      user_call = download(uri)
      JSON.parse(user_call)
    rescue => e
      @logger.warn "Download failed (#{e}) retrying"
      sleep 1
      retry
    end
  end

  def self.video_url(code)
    URI "https://www.instagram.com/p/#{code}/?__a=1"
  end

  def self.add_to_downloads(url, path)
    obj = {
      uri: URI(url),
      path: path
    }

    @semaphore.synchronize do
      @downloads << obj
    end
  end

  def self.initialize_downloads(thread_count)
    @start = Time.now
    @semaphore = Mutex.new
    @logger = Logger.new(STDOUT)
    @downloads = []
    @done = false
    @threads = []

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
          download_to_file(download[:uri], download[:path])
        end
      end
    end
  end

  def self.wait
    @done = true
    @threads.each(&:join)
    puts "Done in #{Time.now - @start}s"
  end


  def self.video_url(code)
    URI "https://www.instagram.com/p/#{code}/?__a=1"
  end

  def self.download(uri, try = 3)
    response = Net::HTTP.get_response uri
    if response.code.to_i >= 399
      if try > 0
        @logger.puts "Downloading #{uri} ended in #{response.code}. Retrying #{try} times."
        download(uri, try - 1)
      else
        response.body
      end
    else
      response.body
    end
  end

  def self.download_to_file(uri, path)
    return if File.exist?(path)
    File.open(path, 'wb') do |file|
      file.write download(uri)
    end
  end
end
