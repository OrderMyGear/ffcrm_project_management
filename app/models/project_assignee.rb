class ProjectAssignee < ActiveRecord::Base
  belongs_to :project
  belongs_to :assignee, class_name: 'User'
end
