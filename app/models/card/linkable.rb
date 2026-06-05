module Card::Linkable
  extend ActiveSupport::Concern

  included do
    has_many :outbound_links, class_name: "CardLink", foreign_key: :from_card_id, dependent: :delete_all, inverse_of: :from_card
    has_many :inbound_links, class_name: "CardLink", foreign_key: :to_card_id, dependent: :delete_all, inverse_of: :to_card
  end

  def decomposition_children
    Card.where(id: outbound_links.of_type("decomposes_into").select(:to_card_id))
  end

  def decomposition_parents
    Card.where(id: inbound_links.of_type("decomposes_into").select(:from_card_id))
  end

  def verification_peers
    Card.where(id: outbound_links.of_type("verifies_at_level").select(:to_card_id))
  end
end
