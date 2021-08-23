# frozen_string_literal: true

module Jobs

  class ProcessTopic < ::Jobs::Base
    #sidekiq_options retry: false

    def execute(args)
      topic = Topic.find(args[:topic_id])
      Demonstrator::process_topic(topic)
    end
  end

end
