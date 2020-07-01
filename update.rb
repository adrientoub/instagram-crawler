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
  users_list = []
  list.each do |filename|
    next if filename[0] == '.' || filename[0] == '#' || filename[0] == '_'

    if File.directory?(filename)
      users_list << filename
    end
  end

  users_list.shuffle.each do |username|
    download_user(username, true)
  end
end
