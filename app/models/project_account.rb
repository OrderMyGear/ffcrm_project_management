class ProjectAccount < ActiveRecord::Base
  belongs_to :project
  belongs_to :account
end
