class Project < ActiveRecord::Base
  belongs_to :user

  has_one :project_account, dependent: :destroy
  has_one :account, through: :project_account

  has_many :project_contacts, dependent: :destroy
  has_many :contacts, through: :project_contacts

  has_many :project_assignees, dependent: :destroy
  has_many :assignees, through: :project_assignees

  has_many :tasks,  :as => :asset, :dependent => :destroy
  has_many :emails, :as => :mediator

  has_many :attachments, :as => :entity
  accepts_nested_attributes_for :attachments, :allow_destroy => true

  serialize :subscribed_users, Set

  acts_as_taggable_on :tags
  uses_user_permissions
  acts_as_commentable
  uses_comment_extensions
  has_paper_trail :ignore => [ :subscribed_users ]
  has_fields
  exportable

  sortable :by => [ "name ASC", "cost_estimate DESC", "created_at DESC", "updated_at DESC" ], :default => "created_at DESC"

  has_ransackable_associations %w(account contacts users tags activities comments)
  ransack_can_autocomplete

  #used by ransack ui to build dropdown select with status and categories
  validates :status,   :inclusion => { :in => Proc.new { Setting.unroll(:project_status).map{|s| s.last.to_s } } }
  validates :category, :inclusion => { :in => Proc.new { Setting.unroll(:project_category).map{|s| s.last.to_s } } }, allow_blank: true

  validates_presence_of :name, :message => :missing_project_name
  validates_numericality_of [:cost_estimate], :allow_nil => true
  validate :users_for_shared_access

  scope :visible_on_dashboard, ->(user) {
    joins('LEFT JOIN project_assignees ON project_assignees.project_id = projects.id').
    where('(user_id = :user_id AND project_assignees.assignee_id IS NULL) OR project_assignees.assignee_id = :user_id', :user_id => user.id)
  }

  scope :my, ->(*args) {
    options = args[0] || {}
    user_option = (options.is_a?(Hash) ? options[:user] : options) || User.current_user
    includes(:assignees).
        where('access = \'Public\' OR user_id = :user_id OR project_assignees.assignee_id = :user_id', :user_id => user_option).
        order(options[:order] || 'name ASC').
        limit(options[:limit]) # nil selects all records
  }

  scope :accessible_by, -> (ability, action) {
    ability.can?(:manage, :all) ? scoped : my
  }

  # Search by name OR id
  scope :text_search, ->(query) {
    if query =~ /\A\d+\z/
      where('upper(name) LIKE upper(:name) OR projects.id = :id', :name => "%#{query}%", :id => query)
    else
      search('name_cont' => query).result
    end
  }

  scope :state, ->(filters) {
    where('status IN (?)' + (filters.delete('other') ? ' OR status IS NULL' : ''), filters)
  }
  scope :unassigned,  -> { joins("INNER JOIN project_assignees on project_assignees.project_id = projects.id").where("project_assignees.id IS NULL") }

  def self.per_page ; 20 ; end
  def self.default_status; Setting[:project_default_status].try(:to_s) || 'active'; end

  #----------------------------------------------------------------------------
  def save_with_account_and_permissions(params)
    # Quick sanitization, makes sure Account will not search for blank id.
    params[:account].delete(:id) if params[:account][:id].blank?
    account = Account.create_or_select_for(self, params[:account])
    self.project_account = ProjectAccount.new(:account => account, :project => self) unless account.id.blank?
    self.account = account
    result = self.save
    self.contacts << Contact.find(params[:contact]) unless params[:contact].blank?
    result
  end

  #----------------------------------------------------------------------------
  def update_with_account_and_permissions(params)
    if params[:account] && (params[:account][:id] == "" || params[:account][:name] == "")
      self.account = nil # Project is not associated with the account anymore.
    elsif params[:account]
      account = Account.create_or_select_for(self, params[:account])
      if self.account != account and account.id.present?
        self.project_account = ProjectAccount.new(:account => account, :project => self)
      end
    end
    self.reload
    # Must set access before user_ids, because user_ids= method depends on access value.
    self.access = params[:project][:access] if params[:project][:access]
    self.attributes = params[:project]
    self.save
  end

  # Attach given attachment to the project if it hasn't been attached already.
  #----------------------------------------------------------------------------
  def attach!(attachment)
    ids_method, association_method = if attachment.is_a?(User)
      ['assignee_ids', 'assignees']
    else
      ["#{attachment.class.name.downcase}_ids", attachment.class.name.tableize]
    end

    unless self.send(ids_method).include?(attachment.id)
      self.send(association_method) << attachment
    end
  end

  # Discard given attachment from the project.
  #----------------------------------------------------------------------------
  def discard!(attachment)
    if attachment.is_a?(Task)
      attachment.update_attribute(:asset, nil)
    elsif attachment.is_a?(User)
      self.assignees.delete(attachment)
    else # Contacts
      self.send(attachment.class.name.tableize).delete(attachment)
    end
  end

  private
  # Make sure at least one user has been selected if the contact is being shared.
  #----------------------------------------------------------------------------
  def users_for_shared_access
    errors.add(:access, :share_project) if self[:access] == "Shared" && !self.permissions.any?
  end

  ActiveSupport.run_load_hooks(:fat_free_crm_project, self)
end