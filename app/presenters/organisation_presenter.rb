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

  def as_json(options = {})
    if options[:partial]
      return minimum_for_json
    else
      {
        response: {
          status: "ok",
          total: subject.documents.count,
          content: minimum_for_json.merge(fields: extra_fields_for_json),
          relations: relationships_for_json,
          contents: subject.documents.collect { |d|
            {
              title: d.title,
              type: d.class.name.split("::").first.underscore,
              updated_at: d.updated_at,
              uri: "#{request.protocol}#{request.host_with_port}#{public_document_path(d, host: request.host)}",
              api_uri: "#{request.protocol}#{request.host_with_port}#{public_document_path(d, format: :json, host: request.host)}"
            }
          }
        }
      }
    end
  end

  def uri(args = {})
    opts = args.merge(host: request.host)
    organisation_url(subject, opts)
  end
end
