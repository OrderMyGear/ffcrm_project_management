require 'project_view_hooks'

module FfcrmProjectManagement
  class Engine < ::Rails::Engine
    initializer :load_config_initializers do
      config.paths["config/initializers"].existent.sort.each do |initializer|
        load(initializer)
      end
    end

    config.to_prepare do
      require 'ffcrm_project_management/ability'
      require 'ffcrm_project_management/account'
      require 'ffcrm_project_management/contact'
      require 'ffcrm_project_management/user'

      ActiveSupport.on_load(:fat_free_crm_account) do
        self.class_eval do
          include FfcrmProjectManagement::Account
        end
      end

      ActiveSupport.on_load(:fat_free_crm_contact) do
        self.class_eval do
          include FfcrmProjectManagement::Contact
        end
      end

      ActiveSupport.on_load(:fat_free_crm_user) do
        self.class_eval do
          include FfcrmProjectManagement::User
        end
      end

      ActiveSupport.on_load(:fat_free_crm_ability) do
        self.send(:prepend, FfcrmProjectManagement::Ability)
      end

      HomeController.class_eval do
        def index
          @activities = get_activities
          @my_tasks = ::Task.visible_on_dashboard(current_user).includes(:user, :asset).by_due_at
          @my_opportunities = ::Opportunity.visible_on_dashboard(current_user).includes(:account, :user, :tags).by_closes_on.by_amount
          @my_accounts = ::Account.visible_on_dashboard(current_user).includes(:user, :tags).by_name
          @my_projects = ::Project.visible_on_dashboard(current_user).includes(:user, :tags, :account)
          respond_with(@activities)
        end
      end

      UsersController.class_eval do
        def opportunities_overview
          @users_with_opportunities_and_projects = ::User.have_assigned_opportunities.have_assigned_projects.order(:first_name)
          @unassigned_opportunities = ::Opportunity.unassigned.pipeline.order(:stage)
          @unassigned_projects      = ::Project.unassigned.order(:status)
        end
      end

      ContactsController.class_eval do
        def create
          @comment_body = params[:comment_body]
          respond_with(@contact) do |format|
            if @contact.save_with_account_and_permissions(params)
              @contact.add_comment_by_user(@comment_body, current_user)
              @contacts = get_contacts if called_from_index_page?
            else
              unless params[:account][:id].blank?
                @account = Account.find(params[:account][:id])
              else
                if request.referer =~ /\/accounts\/(\d+)\z/
                  @account = Account.find($1) # related account
                else
                  @account = Account.new(:user => current_user)
                end
              end
              @opportunity = Opportunity.my.find(params[:opportunity]) unless params[:opportunity].blank?
              @project = Project.my.find(params[:project]) unless params[:project].blank?
            end
          end
        end
      end

      ApplicationHelper.class_eval do
        def jumpbox(current)
          tabs = [ :campaigns, :accounts, :leads, :contacts, :projects, :opportunities]
          current = tabs.first unless tabs.include?(current)
          tabs.map do |tab|
            link_to_function(t("tab_#{tab}"), "crm.jumper('#{tab}')", "html-data" => tab, :class => (tab == current ? 'selected' : ''))
          end.join(" | ").html_safe
        end
      end
    end
  end
end
