require 'active_support/concern'

module FfcrmProjectManagement
  module User
    extend ActiveSupport::Concern

    included do
      has_many  :project_assignees, :dependent => :destroy, :foreign_key => :assignee_id
      has_many  :projects, :through => :project_assignees

      scope :have_assigned_projects, -> {
        joins("INNER JOIN project_assignees ON project_assignees.assignee_id = users.id")
        .select('DISTINCT(users.id), users.*')
      }
    end
  end
end