module Admin::EditionsHelper
  def nested_attribute_destroy_checkbox_options(form)
    checked_value, unchecked_value = '0', '1'
    checked = form.object[:_destroy].present? ? (form.object[:_destroy] == checked_value) : form.object.persisted?
    [{ checked: checked }, checked_value, unchecked_value]
  end

  def admin_documents_header_link
    admin_header_link "Documents", admin_editions_path, /^#{Whitehall.router_prefix}\/admin\/(documents|publications|policies|news_articles|consultations|speeches)/
  end

  def link_to_filter(link, options, html_options={})
    content_tag(:li, link_to(link, url_for(params.slice('state', 'type', 'author', 'organisation').merge(options)), html_options), class: filter_class(options))
  end

  def filter_class(options)
    current = options.keys.all? do |key|
      options[key].to_param == params[key].to_param
    end

    'active' if current
  end

  def viewing_all_active_editions?
    params[:state] == 'active'
  end

  def show_featuring_controls?(*editions)
    !viewing_all_active_editions? && params[:type] && editions.any?(&:featurable?)
  end

  MS_WORD_DOCUMENT_HUMANIZED_CONTENT_TYPE = "MS Word Document"
  MS_EXCEL_SPREADSHEET_HUMANIZED_CONTENT_TYPE = "MS Excel Spreadsheet"
  MS_POWERPOINT_PRESENTATION_HUMANIZED_CONTENT_TYPE = "MS Powerpoint Presentation"

  FILE_EXTENSION_VS_HUMANIZED_CONTENT_TYPE = {
    "pdf" => "PDF Document",
    "csv" => "CSV Document",
    "rtf" => "RTF Document",
    "png" => "PNG Image",
    "jpg" => "JPEG Document",
    "doc" => MS_WORD_DOCUMENT_HUMANIZED_CONTENT_TYPE,
    "docx" => MS_WORD_DOCUMENT_HUMANIZED_CONTENT_TYPE,
    "xls" => MS_EXCEL_SPREADSHEET_HUMANIZED_CONTENT_TYPE,
    "xlsx" => MS_EXCEL_SPREADSHEET_HUMANIZED_CONTENT_TYPE,
    "ppt" => MS_POWERPOINT_PRESENTATION_HUMANIZED_CONTENT_TYPE,
    "pptx" => MS_POWERPOINT_PRESENTATION_HUMANIZED_CONTENT_TYPE
  }

  def humanized_content_type(file_extension)
    FILE_EXTENSION_VS_HUMANIZED_CONTENT_TYPE[file_extension.downcase] if file_extension.present?
  end

  def order_link(edition)
    return "" unless edition.order_url.present?
    link_to edition.order_url, edition.order_url, class: "order_url"
  end

  def standard_edition_form(edition, &blk)
    form_for [:admin, edition], as: :edition do |form|
      concat form.errors
      concat render(partial: "standard_fields",
                    locals: {form: form, edition: edition})
      yield(form)
      if edition.change_note_required?
        concat content_tag(:fieldset,
          form.text_area(:change_note, rows: 4, label_text:
                         "Change note (will appear on public site)") +
          form.check_box(:minor_change, label_text:
                         "Minor change? (for typos and other minor corrections, nothing will appear on public site)"))
      end
      concat form.save_or_cancel
    end
  end
end
