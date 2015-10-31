class MentionObserver < ActiveRecord::Observer

    def after_create(mention)
        if Setting.notified_events.include?('user_mentioned') &&
           %w(all only_my_events only_owner).include?(mention.mentioned.mail_notification) &&
           mention.title.present? && mention.url.present? && mention.created_on > 1.day.ago &&
           (!mention.mentioning.respond_to?(:visible?) || mention.mentioning.visible?(mention.mentioned))
            if Rails::VERSION::MAJOR < 3
                Mailer.deliver_mention(mention)
            else
                Mailer.mention(mention).deliver
            end
        end
    rescue Exception => exception
        Rails.logger.error exception.message
    end

end
