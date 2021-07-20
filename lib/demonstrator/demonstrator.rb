# frozen_string_literal: true
FILENAME_REGEX = /\[(.+?\.xls\|attachment\])\(upload:\/\/(.+?\.xls)\)/
local_store = FileStore::LocalStore.new

class Demonstrator

  require 'spreadsheet'

  def self.process_topic(topic)
    puts "Processing #{topic.id}"
    filename = get_demonstrator_filename(topic)
    puts "---> found filename: #{filename}"
    ids = get_demonstrator_ids(filename)
    puts "----> got IDS: #{ids.count}"
    invited_by = User.find(topic.user_id)
    puts "------> invited by #{invited_by.username}"
    invite_missing(ids, invited_by)
  end

  def self.can_process_topic
    demonstrator_group = Group.find_by_name(SiteSetting.demonstrator_group)
    demonstrator_manager_group = Group.find_by_name(SiteSetting.demonstrator_manager_group)
    demonstrator_removed_group = Group.find_by_name(SiteSetting.demonstrator_removed_group)
    demonstrator_category = Category.find_by_name(SiteSetting.demonstrator_category)

    (demonstrator_group &&
    demonstrator_manager_group &&
    demonstrator_removed_group &&
    demonstrator_category)
  end

  def self.get_demonstrator_filename(topic)
    local_store = FileStore::LocalStore.new
    p = Post.find_by(topic_id: topic.id, post_number: 1)
    m = FILENAME_REGEX.match(p.raw)
    short_url = m[2]
    u = Upload.find_by(sha1: Upload.sha1_from_short_url(short_url))
    filename = local_store.path_for(u)
  end

  def self.get_demonstrator_ids(filename)
    puts "Reading #{filename}"
    ids = []
    book = Spreadsheet.open(filename)
    sheet = book.worksheet 0
    email_column = sheet.first.find_index('Email')
    sheet.each 1 do |row|
      next unless row[0] && row[email_column]
      ids.append({ id: row[0], email: row[email_column] })
    end
    ids
  end

  def self.invite_missing(ids, invited_by)
    group = Group.find_by_name(SiteSetting.demonstrator_group)
    ids.each do |id|
      puts "---->invite #{id[:id]} -- #{id[:email]}"
      next if UserCustomField.find_by(value: id[:id])
      opts = {}
      opts[:email] = id[:email]
      opts[:group_ids] = [group.id]
      puts "GOING TO INVITE!!!!!  #{opts}"
      Invite.generate(invited_by, opts)
    end
  end

end
