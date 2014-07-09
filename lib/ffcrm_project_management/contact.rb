require 'active_support/concern'

module FfcrmProjectManagement
  module Contact
    extend ActiveSupport::Concern

    included do
      has_many  :project_contacts, :dependent => :destroy
      has_many  :projects, :through => :project_contacts, :uniq => true, :order => "projects.id DESC"

      def save_with_account_and_permissions_with_project(params)
        result = save_with_account_and_permissions_without_project(params)
        self.projects << Project.find(params[:project]) unless params[:project].blank?
        result
      end

      alias_method_chain :save_with_account_and_permissions, :project
    end
  end
end