class Admin::InternationalPrioritiesController < Admin::EditionsController
  before_filter :build_image, only: [:new, :edit]

  private

  def edition_class
    InternationalPriority
  end
end
