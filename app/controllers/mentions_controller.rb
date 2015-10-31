class MentionsController < ApplicationController
    include ApplicationHelper

    before_filter :find_user

    def index
        count = 0
        @offset = 0
        options = {}
        if params[:offset]
            options[:offset] = params[:offset].to_i
            options[:limit] = 2**32
            @prev_offset = @offset = options[:offset]
        end
        if params[:next_offset] && params[:next_offset].to_i > 0
            @next_offset = params[:next_offset].to_i
        elsif @offset > 0
            @next_offset = 0
        end
        mentions = []
        Mention.find(:all, options.merge(
                     :conditions => { :mentioned_id => @user.id },
                     :order => "created_on DESC")).each do |mention|
            if mention.title.present? && (!mention.mentioning.respond_to?(:visible?) || mention.mentioning.visible?)
                mentions << mention
                count += 1
            end
            @offset += 1
            break if count == 50
        end
        @mentions_by_day = mentions.group_by do |mention|
            mention.created_on.to_date
        end
    end

private

    # A copy of #find_user in UsersController
    def find_user
        if params[:id] == 'current'
            require_login || return
            @user = User.current
        else
            @user = User.find(params[:id])
        end
    rescue ActiveRecord::RecordNotFound
        render_404
    end

end
