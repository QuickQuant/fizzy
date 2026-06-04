class CardLink < ApplicationRecord
  LINK_TYPES = %w[ decomposes_into verifies_at_level ].freeze

  belongs_to :account, default: -> { from_card.account }
  belongs_to :from_card, class_name: "Card", inverse_of: :outbound_links
  belongs_to :to_card, class_name: "Card", inverse_of: :inbound_links

  validates :link_type, inclusion: { in: LINK_TYPES }
  validates :from_card_id, uniqueness: { scope: [ :to_card_id, :link_type ] }
  validate :no_self_link
  validate :same_account

  scope :of_type, ->(type) { where(link_type: type) }

  private
    def no_self_link
      if from_card_id == to_card_id
        errors.add(:to_card_id, "cannot link a card to itself")
      end
    end

    def same_account
      if from_card && to_card && from_card.account_id != to_card.account_id
        errors.add(:base, "cross-account links are not allowed")
      end
    end
end
