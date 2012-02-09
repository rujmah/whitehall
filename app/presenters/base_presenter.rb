class BasePresenter
  include Rails.application.routes.url_helpers
  include PublicDocumentRoutesHelper

  attr_accessor :controller, :subject
  delegate :params, :to => :controller
  delegate :request, :to => :controller
  delegate :errors, :to => :subject

  def initialize(controller, subject)
    @controller = controller
    @subject = subject
  end
end