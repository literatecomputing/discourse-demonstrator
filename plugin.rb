# frozen_string_literal: true

# name: discourse-demonstrator
# about: Send invites to new demonstrators
# version: 0.0.1
# authors: Pfaffman
# url: TODO

#gem 'gimite-google-spreadsheet-ruby', '0.0.5', { require: false }
gem 'ruby-ole', '1.2.12', { require: false }
gem "spreadsheet", "1.2.0", { require: false }

enabled_site_setting :demonstrator_enabled
load File.expand_path('lib/demonstrator/demonstrator.rb', __dir__)

after_initialize do
  puts "Hello, world"
  add_model_callback(Topic, :after_create) do
    puts "----> doing the callback for #{self.title}"
    d_cat = Category.find_by_name(SiteSetting.demonstrator_category)
    puts "got new post in #{d_cat.name}"
    Demonstrator::process_topic(:self) if d_cat == self
  end
end
