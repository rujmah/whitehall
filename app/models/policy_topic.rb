class PolicyTopic < ActiveRecord::Base
  include ActiveRecord::Transitions

  state_machine do
    state :current
    state :deleted

    event :delete do
      transitions from: [:current], to: :deleted, guard: :destroyable?
    end
  end

  has_many :policy_topic_memberships
  has_many :policies, through: :policy_topic_memberships
  has_many :featured_policies, through: :policy_topic_memberships, class_name: "Policy", conditions: { "policy_topic_memberships.featured" => true, "documents.state" => "published" }, source: :policy

  has_many :organisation_policy_topics
  has_many :organisations, through: :organisation_policy_topics

  has_many :published_policies, through: :policy_topic_memberships, class_name: "Policy", conditions: { state: "published" }, source: :policy
  has_many :archived_policies, through: :policy_topic_memberships, class_name: "Policy", conditions: { state: "archived" }, source: :policy

  has_many :policy_topic_relations
  has_many :related_policy_topics, through: :policy_topic_relations, before_remove: -> pa, rpa {
    PolicyTopicRelation.relation_for(pa.id, rpa.id).destroy_inverse_relation
  }

  validates :name, presence: true, uniqueness: true
  validates :description, presence: true

  accepts_nested_attributes_for :policy_topic_memberships

  default_scope where('policy_topics.state != "deleted"')

  extend FriendlyId
  friendly_id :name, use: :slugged

  EXEMPLAR_NAMES = [
    "Regulation reform",
    "Higher education",
    "Housing",
    "Local government",
  ]

  def self.exemplars
    where(name: EXEMPLAR_NAMES)
  end

  def should_generate_new_friendly_id?
    new_record?
  end

  def normalize_friendly_id(value)
    value = value.gsub(/'/, '') if value
    super value
  end

  def self.with_published_policies
    joins(:published_policies).group(:policy_topic_id)
  end

  def published_related_documents
    policies.published.includes(
      :published_related_documents
    ).map(&:published_related_documents).flatten.uniq
  end

  def destroyable?
    non_archived_policies = policies - archived_policies
    non_archived_policies.blank?
  end

  def feature
    update_attributes(featured: true)
  end

  def unfeature
    update_attributes(featured: false)
  end

  private

  class << self
    def randomized
      order('RAND()')
    end

    def featured
      where(featured: true)
    end
  end
end
