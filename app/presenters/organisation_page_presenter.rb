class OrganisationPagePresenter < BasePresenter
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