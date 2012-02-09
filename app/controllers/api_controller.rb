class ApiController < ApplicationController
  respond_to :json

	def index
    organisations = Organisation.ordered_by_name_ignoring_prefix
    respond_with OrganisationPagePresenter.new(self, organisations)
	end
end
