# frozen_string_literal: true
FILENAME_REGEX = /\[(.+?\.xls\|attachment\])\(upload:\/\/(.+?\.xls)\)/

class Demonstrator

  require 'spreadsheet'

  def self.process_topic(topic)
    puts "-----> Processing #{topic.id}"
    filename = get_demonstrator_filename(topic)
    puts "---> found filename: #{filename}"
    ids = get_demonstrator_ids(filename)
    puts "----> got IDS: #{ids.count}"
    invited_by = User.find(topic.user_id)
    puts "------> invited by #{invited_by.username}"
    invite_missing(ids, invited_by)
    remove_missing_id(ids)
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
    puts "getting filename from #{topic.id}"
    local_store = FileStore::LocalStore.new
    puts "---> Got local_store"
    p = Post.find_by(topic_id: topic.id, post_number: 1)
    puts "---> Got post #{p.id}"
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
    id_column = sheet.first.find_index('Demonstrator ID')
    sheet.each 1 do |row|
      ids.append({ id: row[id_column], email: row[email_column] })
    end
    ids
  end

  def self.invite_missing(ids, invited_by)
    puts "----> processing invite_missing fpr #{ids}"
    group = Group.find_by_name(SiteSetting.demonstrator_group)
    ids.each do |id|
      next unless id[:id]
      puts "---->checking invite #{id[:id]} -- #{id[:email]}"
      next if UserCustomField.find_by(value: id[:id], name: SiteSetting.demonstrator_ucf)
      next if User.find_by_email(id[:email])
      opts = {}
      opts[:email] = id[:email]
      opts[:group_ids] = [group.id]
      puts "GOING TO INVITE!!!!!  #{opts}"
      Invite.generate(invited_by, opts)
    end
  end

  def self.remove_missing_id(ids)
    puts "----> going to remove!!!"
    demonstrator_ids = ids.map { |i| i[:id] }
    puts "---->  here are the IDS #{demonstrator_ids}"
    manager_group = Group.find_by_name(SiteSetting.demonstrator_manager_group)
    removed_group = Group.find_by_name(SiteSetting.demonstrator_removed_group)
    demo_group = Group.find_by_name(SiteSetting.demonstrator_group)
    users = User.all
    users.each do |user|
      puts "----> chjekcing user #{user.username}"
      next if user.staff?
      puts "not staff"
      next if GroupUser.find_by(user_id: user.id, group_id: manager_group.id)
      puts "not manager"
      ucf = UserCustomField.find_by(user_id: user.id, name: SiteSetting.demonstrator_ucf)
      puts "ucf: #{ucf}"
      next if ucf && demonstrator_ids.include?(ucf.value)
      puts "have ucf"
      user.email = "#{user.username}@removed.invalid"
      user.active = false
      user.save
      demo_group_user = GroupUser.find_by(user_id: user.id, group_id: demo_group.id)
      demo_group_user.destroy if demo_group_user
      GroupUser.find_or_create_by(user_id: user.id, group_id: removed_group.id)
      Rails.logger.warn("Removing user #{user.username}")
    end
  end

end
