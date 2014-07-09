module FfcrmProjectManagement
  module Ability
    def initialize(user)
      super

      if user.present?
        # Projects
        can :manage, Project, access: 'Public'
        can :manage, Project, user_id: user.id
        can :manage, Project, :assignees => { id: user.id }

        unless user.admin?
          t = Permission.arel_table
          scope = t[:user_id].eq(user.id)

          if (group_ids = user.group_ids).any?
            scope = scope.or(t[:group_id].eq_any(group_ids))
          end

          if (asset_ids = Permission.where(scope.and(t[:asset_type].eq(Project.name))).value_of(:asset_id)).any?
            can :manage, Project, :id => asset_ids
          end
        end
      end
    end
  end
end