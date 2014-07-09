require 'active_support/concern'

module FfcrmProjectManagement
  module Account
    extend ActiveSupport::Concern

    included do
      has_many  :project_accounts, :dependent => :destroy
      has_many  :projects, :through => :project_accounts, :uniq => true, :order => "projects.id DESC"
    end
  end
end