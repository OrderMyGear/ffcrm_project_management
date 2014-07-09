xml.Worksheet 'ss:Name' => I18n.t(:tab_projects) do
  xml.Table do
    unless @projects.empty?
      # Header.
      xml.Row do
        heads = [I18n.t('id'),
                 I18n.t('user'),
                 I18n.t('campaign'),
                 I18n.t('assigned_to'),
                 I18n.t('account'),
                 I18n.t('name'),
                 I18n.t('access'),
                 I18n.t('source'),
                 I18n.t('status'),
                 I18n.t('probability'),
                 I18n.t('amount'),
                 I18n.t('discount'),
                 I18n.t('weighted_amount'),
                 I18n.t('option_closes_on'),
                 I18n.t('date_created'),
                 I18n.t('date_updated')]

        # Append custom field labels to header
        Opportunity.fields.each do |field|
          heads << field.label
        end

        heads.each do |head|
          xml.Cell do
            xml.Data head,
                     'ss:Type' => 'String'
          end
        end
      end

      # Opportunity rows.
      @projects.each do |project|
        xml.Row do
          data = [project.id,
                  project.user.try(:name),
                  project.campaign.try(:name),
                  project.assignee.try(:name),
                  project.account.try(:name),
                  project.name,
                  project.access,
                  project.source,
                  project.status,
                  project.probability,
                  project.amount,
                  project.discount,
                  project.weighted_amount,
                  project.closes_on,
                  project.created_at,
                  project.updated_at]

          # Append custom field values.
          Opportunity.fields.each do |field|
            data << project.send(field.name)
          end

          data.each do |value|
            xml.Cell do
              xml.Data value,
                       'ss:Type' => "#{value.respond_to?(:abs) ? 'Number' : 'String'}"
            end
          end
        end
      end
    end
  end
end
