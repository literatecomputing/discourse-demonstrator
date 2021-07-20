# frozen_string_literal: true

module Jobs

  class ProcessTopic < ::Jobs::Base
    #sidekiq_options retry: false

    def execute(args)
      puts "----> execute process_topic for #{args[:topic_id]}"
      topic = Topic.find(args[:topic_id])
      puts "-----> got topic!! #{topic.title}"
      Demonstrator::process_topic(topic)
    end
  end

end
