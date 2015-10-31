module MentionObserver

  def self.included(base)
    base.send(:include, InstanceMethods)
    base.instance_eval do
      unloadable
      after_create :handle_mention
    end

  end

  module InstanceMethods

    def handle_mention
      mention = self
      if Setting.notified_events.include?('user_mentioned') &&
          %w(all only_my_events only_owner).include?(mention.mentioned.mail_notification) &&
          mention.title.present? && mention.url.present? && mention.created_on > 1.day.ago &&
          (!mention.mentioning.respond_to?(:visible?) || mention.mentioning.visible?(mention.mentioned))

        Mailer.mention(mention).deliver

      end
    rescue Exception => exception
      Rails.logger.error exception.message
    end

  end
end