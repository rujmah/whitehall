module PublicDocumentRoutesHelper
  def public_document_path(edition, options = {})
    options.merge!(document_url_options(edition))
    polymorphic_path(model_name(edition), options)
  end

  def public_document_url(edition, options={})
    options.merge!(document_url_options(edition))
    if host = Whitehall.public_host_for(request.host)
      options.merge!(host: host)
    end
    polymorphic_url(model_name(edition), options)
  end

  def public_supporting_page_path(edition, supporting_page, options = {})
    policy_supporting_page_path(edition.document, supporting_page, options)
  end

  def public_supporting_page_url(edition, supporting_page, options={})
    if host = Whitehall.public_host_for(request.host)
      policy_supporting_page_url(edition.document, supporting_page, options.merge(host: host))
    else
      public_supporting_page_path(edition, supporting_page, options)
    end
  end

  def edit_admin_supporting_page_path(supporting_page, options={})
    edit_admin_edition_supporting_page_path(supporting_page.edition, supporting_page, options)
  end

  def edit_admin_supporting_page_url(supporting_page, options={})
    edit_admin_edition_supporting_page_url(supporting_page.edition, supporting_page, options)
  end

  def admin_supporting_page_path(supporting_page, options={})
    admin_edition_supporting_page_path(supporting_page.edition, supporting_page, options)
  end

  def admin_supporting_page_url(supporting_page, options={})
    admin_edition_supporting_page_url(supporting_page.edition, supporting_page, options)
  end

  private

  def document_url_options(edition)
    if edition.is_a?(ConsultationResponse)
      {consultation_id: edition.consultation.document}
    else
      {id: edition.document}
    end
  end

  def model_name(edition)
    edition.class.name.split("::").first.underscore
  end
end
