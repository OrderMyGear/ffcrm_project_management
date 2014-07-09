module ProjectsHelper

  #----------------------------------------------------------------------------
  def section_without_create(related, assets)
    asset = assets.to_s.singularize
    select_id  = "select_#{asset}"

    html = tag(:br)
    html << content_tag(:div, link_to(t(select_id), "#", :id => select_id), :class => "subtitle_tools")
    html << content_tag(:div, t(assets), :class => :subtitle, :id => "create_#{asset}_title")
  end

  #----------------------------------------------------------------------------
  def project_status_checkbox(status, count)
    entity_filter_checkbox(:status, status, count)
  end

  # Generates a select list with the first 25 campaigns
  # and prepends the currently selected campaign, if any.
  #----------------------------------------------------------------------------
  def project_assignees_select(options = {})
    options[:selected] ||= @project.assignee_ids || 0
    selected_users = User.my.where(id: options[:selected]).to_a
    users = (selected_users + User.my.by_name.limit(25)).compact.uniq
    collection_select :project, :assignee_ids, users, :id, :full_name, options,
                      {:"data-placeholder" => t(:select_a_user),
                       :"data-url" => auto_complete_users_path(format: 'json'),
                       style: "width:330px; display:none;", multiple: true,
                       class: 'ajax_chosen' }
  end


  def project_contacts_select(options = {})
    options[:selected] ||= @project.contact_ids || 0
    selected_contacts = Contact.my.where(id: options[:selected]).to_a
    contacts = selected_contacts#(selected_contacts + Contact.my.limit(25)).compact.uniq
    select_tag 'project[contact_ids]', options_from_collection_for_select(contacts, :id, :full_name, options[:selected]),
                      {:"data-placeholder" => t(:select_a_contact),
                       :"data-url" => auto_complete_contacts_path(format: 'json'),
                       style: "width:330px; display:none;", multiple: true,
                       include_blank: true,
                       class: 'ajax_chosen_1' }
  end
end