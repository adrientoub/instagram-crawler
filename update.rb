require 'fileutils'

def update(limit)
  list = Dir.entries('.')
  puts 'Updating all already downloaded users and hashtags'
  list.each do |filename|
    next if filename[0] == '.'
    if File.directory?(filename)
      if filename[0] == '#'
        download_hashtag(filename[1..-1], limit)
      else
        update_user(filename)
      end
    end
  end
end

def update_hashtags(limit)
  list = Dir.entries('.')
  puts 'Updating all already downloaded hashtags'
  list.each do |filename|
    next if filename[0] != '#'
    if File.directory?(filename)
      download_hashtag(filename[1..-1], limit)
    end
  end
end

def update_users
  list = Dir.entries('.')
  puts 'Updating all already downloaded users'
  list.each do |filename|
    next if filename[0] == '.' || filename[0] == '#'

    if File.directory?(filename)
      download_user(filename)
    end
  end
end
