class ApiController < ApplicationController
  respond_to :json

  def index
    organisations = Organisation.ordered_by_name_ignoring_prefix
    respond_with OrganisationPagePresenter.new(self, organisations)
	end

	def show
    organisation = Organisation.find(params[:id])
    respond_with OrganisationPresenter.new(self, organisation)
  end
end
