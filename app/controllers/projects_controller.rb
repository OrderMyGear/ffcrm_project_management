# Copyright (c) 2008-2013 Michael Dvorkin and contributors.
#
# Fat Free CRM is freely distributable under the terms of MIT license.
# See MIT-LICENSE file or http://www.opensource.org/licenses/mit-license.php
#------------------------------------------------------------------------------
class ProjectsController < EntitiesController
  before_filter :load_settings
  before_filter :get_data_for_sidebar, :only => :index
  before_filter :set_params, :only => [ :index, :redraw, :filter ]

  # GET /projects
  #----------------------------------------------------------------------------
  def index
    @projects = get_projects(:page => params[:page], :per_page => params[:per_page])

    respond_with @projects do |format|
      format.xls { render :layout => 'header' }
      format.csv { render :csv => @projects }
    end
  end

  # GET /projects/1
  # AJAX /projects/1
  #----------------------------------------------------------------------------
  def show
    @comment = Comment.new
    @timeline = timeline(@project)
    respond_with(@project)
  end

  # GET /projects/new
  #----------------------------------------------------------------------------
  def new
    @project.attributes = {:user => current_user, :status => Project.default_status, :access => Setting.default_access }
    @account     = Account.new(:user => current_user, :access => Setting.default_access)
    @accounts    = Account.my.order('name')

    if params[:related]
      model, id = params[:related].split('_')
      if related = model.classify.constantize.my.find_by_id(id)
        instance_variable_set("@#{model}", related)
        @account = related.account if related.respond_to?(:account) && !related.account.nil?
      else
        respond_to_related_not_found(model) and return
      end
    end

    respond_with(@project)
  end

  # GET /projects/1/edit                                              AJAX
  #----------------------------------------------------------------------------
  def edit
    @account  = @project.account || Account.new(:user => current_user)
    @accounts = Account.my.order('name')

    if params[:previous].to_s =~ /(\d+)\z/
      @previous = Project.accessible_by(current_ability, :manage).find_by_id($1) || $1.to_i
    end

    respond_with(@project)
  end

  # POST /projects
  #----------------------------------------------------------------------------
  def create
    @comment_body = params[:comment_body]
    respond_with(@project) do |format|
      if @project.save_with_account_and_permissions(params)
        @project.add_comment_by_user(@comment_body, current_user)
        if called_from_index_page?
          @projects = get_projects
          get_data_for_sidebar
        elsif called_from_landing_page?(:accounts)
          get_data_for_sidebar(:account)
        end
      else
        @accounts = Account.my.order('name')
        unless params[:account][:id].blank?
          @account = Account.find(params[:account][:id])
        else
          if request.referer =~ /\/accounts\/(\d+)\z/
            @account = Account.find($1) # related account
          else
            @account = Account.new(:user => current_user)
          end
        end
        @contact = Contact.find(params[:contact]) unless params[:contact].blank?
      end
    end
  end

  # PUT /projects/1
  #----------------------------------------------------------------------------
  def update
    respond_with(@project) do |format|
      if @project.update_with_account_and_permissions(params)
        if called_from_index_page?
          get_data_for_sidebar
        elsif called_from_landing_page?(:accounts)
          get_data_for_sidebar(:account)
        elsif called_from_landing_page?(:campaigns)
          get_data_for_sidebar(:campaign)
        end
      else
        @accounts = Account.my.order('name')
        if @project.account
          @account = Account.find(@project.account.id)
        else
          @account = Account.new(:user => current_user)
        end
      end
    end
  end

  # DELETE /projects/1
  #----------------------------------------------------------------------------
  def destroy
    if called_from_landing_page?(:accounts)
      @account = @project.account   # Reload related account if any.
    elsif called_from_landing_page?(:campaigns)
      @campaign = @project.campaign # Reload related campaign if any.
    end
    @project.destroy

    respond_with(@project) do |format|
      format.html { respond_to_destroy(:html) }
      format.js   { respond_to_destroy(:ajax) }
    end
  end

  # PUT /projects/1/attach
  #----------------------------------------------------------------------------
  # Handled by EntitiesController :attach

  # POST /projects/1/discard
  #----------------------------------------------------------------------------
  # Handled by EntitiesController :discard

  # POST /projects/auto_complete/query                                AJAX
  #----------------------------------------------------------------------------
  # Handled by ApplicationController :auto_complete

  # GET /projects/redraw                                              AJAX
  #----------------------------------------------------------------------------
  def redraw
    @projects = get_projects(:page => 1, :per_page => params[:per_page])
    set_options # Refresh options

    respond_with(@projects) do |format|
      format.js { render :index }
    end
  end

  # POST /projects/filter                                             AJAX
  #----------------------------------------------------------------------------
  def filter
    @projects = get_projects(:page => 1, :per_page => params[:per_page])
    respond_with(@projects) do |format|
      format.js { render :index }
    end
  end

  private

  #----------------------------------------------------------------------------
  alias :get_projects :get_list_of_records

  #----------------------------------------------------------------------------
  def respond_to_destroy(method)
    if method == :ajax
      if called_from_index_page?
        get_data_for_sidebar
        @projects = get_projects
        if @projects.blank?
          @projects = get_projects(:page => current_page - 1) if current_page > 1
          render :index and return
        end
      else # Called from related asset.
        self.current_page = 1
      end
      # At this point render destroy.js
    else
      self.current_page = 1
      flash[:notice] = t(:msg_asset_deleted, @project.name)
      redirect_to projects_path
    end
  end

  #----------------------------------------------------------------------------
  def get_data_for_sidebar(related = false)
    if related
      instance_variable_set("@#{related}", @project.send(related)) if called_from_landing_page?(related.to_s.pluralize)
    else
      @project_status_total = { :all => Project.accessible_by(current_ability, :manage).count, :other => 0 }
      @status.each do |value, key|
        @project_status_total[key] = Project.accessible_by(current_ability, :manage).where(:status => key.to_s).count
        @project_status_total[:other] -= @project_status_total[key]
      end
      @project_status_total[:other] += @project_status_total[:all]
    end
  end

  #----------------------------------------------------------------------------
  def load_settings
    @status = Setting.unroll(:project_status)
    @category = Setting.unroll(:project_category)
  end

  #----------------------------------------------------------------------------
  def set_params
    current_user.pref[:projects_per_page] = params[:per_page] if params[:per_page]
    current_user.pref[:projects_sort_by]  = Project::sort_by_map[params[:sort_by]] if params[:sort_by]
    session[:projects_filter] = params[:status] if params[:status]
  end
end
