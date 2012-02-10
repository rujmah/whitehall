class OrganisationPresenter < BasePresenter
  def minimum_for_json
    {
      name: subject.name,
      uri: uri,
      api_uri: uri(format: 'json'),
      type: 'organisation'
    }
  end

  def extra_fields_for_json
    {
      description: subject.description,
      about_us: subject.about_us,
      organisation_type: subject.organisation_type.name,
      acronym: subject.acronym 
    }    
  end

  def relationships_for_json
    return []
  end

  def type_identifier(d)
    d.class.name.split("::").first.underscore.singularize
  end

  def as_json(options = {})
    if options[:partial]
      return minimum_for_json
    else
      response = {
        response: {
          status: "ok",
          total: subject.documents.count,
          content: minimum_for_json.merge(fields: extra_fields_for_json),
          relations: relationships_for_json
        }
      }
      if subject.respond_to?(:documents)
        response[:contents] = subject.documents.collect do |d|
          {
            title: d.title,
            type: type_identifier(d),
            updated_at: d.updated_at,
            uri: "#{request.protocol}#{request.host_with_port}#{public_document_path(d, host: request.host)}",
            api_uri: api_resource_url(resource_type: type_identifier(d), id: d, format: :json, host: request.host)
          }
        end
      end
      response
    end
  end

  def uri(args = {})
    opts = args.merge(host: request.host)
    organisation_url(subject, opts)
  end
end
