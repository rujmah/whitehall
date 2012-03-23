class EditorialRemark < ActiveRecord::Base
  belongs_to :document, inverse_of: :editorial_remarks
  belongs_to :author, class_name: "User"

  validates :document, :body, :author, presence: true
end