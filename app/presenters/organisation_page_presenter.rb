class OrganisationPagePresenter
  include Rails.application.routes.url_helpers

  attr_accessor :controller, :subject
  delegate :params, :to => :controller
  delegate :errors, :to => :subject

  def initialize(controller, subject)
    @controller = controller
    @subject = subject
  end

  def as_json(options = {})
  	{
  		response: {
        status: "ok",
        total: subject.count,
        results: subject.map { |o| OrganisationPresenter.new(controller, o).as_json(partial: true) }
      }
  	}
  end
end