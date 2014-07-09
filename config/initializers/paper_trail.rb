# Copyright (c) 2008-2013 Michael Dvorkin and contributors.
#
# Fat Free CRM is freely distributable under the terms of MIT license.
# See MIT-LICENSE file or http://www.opensource.org/licenses/mit-license.php
#------------------------------------------------------------------------------
require 'paper_trail'

Version.class_eval do
  class << self
    def visible_to(user)
      scoped.delete_if do |version|
        if item = version.item || version.reify
          if item.respond_to?(:access) # NOTE: Tasks don't have :access as of yet.
            # Delete from scope if it shouldn't be visible
            next item.user_id != user.id && !assigned_to_user?(item, user) &&
                (item.access == "Private" || (item.access == "Shared" && !item.permissions.map(&:user_id).include?(user.id)))
          end
          # Don't delete any objects that don't have :access method (e.g. tasks)
          next false
        end
        # Delete from scope if no object can be found or reified (e.g. from 'show' events)
        true
      end
    end

    private

    def assigned_to_user?(item, user)
      if item.respond_to?(:assigned_to)
        item.assigned_to == user.id
      elsif item.respond_to?(:assignees)
        item.assignee_ids.include?(user.id)
      else
        false
      end
    end
  end
end
