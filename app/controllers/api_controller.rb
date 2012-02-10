class ApiController < ApplicationController
  respond_to :json

  def index
    respond_with OrganisationPagePresenter.new(self, collection)
  end

	def show
    respond_with OrganisationPresenter.new(self, resource)
  end

protected
  def collection
    Organisation.ordered_by_name_ignoring_prefix
  end

  def resource
    Organisation.find(params[:id])
  end
end
