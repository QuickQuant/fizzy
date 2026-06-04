require "test_helper"

class CardLinkTest < ActiveSupport::TestCase
  test "rejects self-link" do
    link = CardLink.new(from_card: cards(:logo), to_card: cards(:logo), link_type: "decomposes_into")

    assert_not link.valid?
    assert_includes link.errors[:to_card_id], "cannot link a card to itself"
  end

  test "rejects duplicate link type for an ordered pair" do
    from_card = cards(:logo)
    to_card = cards(:layout)
    CardLink.create!(from_card: from_card, to_card: to_card, link_type: "decomposes_into")

    duplicate = CardLink.new(from_card: from_card, to_card: to_card, link_type: "decomposes_into")

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:from_card_id], "has already been taken"
  end

  test "allows different link types for the same ordered pair" do
    from_card = cards(:logo)
    to_card = cards(:layout)
    CardLink.create!(from_card: from_card, to_card: to_card, link_type: "decomposes_into")

    peer = CardLink.new(from_card: from_card, to_card: to_card, link_type: "verifies_at_level")

    assert peer.valid?
  end

  test "rejects cross-account link" do
    link = CardLink.new(from_card: cards(:logo), to_card: cards(:radio), link_type: "decomposes_into")

    assert_not link.valid?
    assert_includes link.errors[:base], "cross-account links are not allowed"
  end

  test "rejects unknown link type" do
    link = CardLink.new(from_card: cards(:logo), to_card: cards(:layout), link_type: "depends_on")

    assert_not link.valid?
    assert_includes link.errors[:link_type], "is not included in the list"
  end

  test "destroying a card deletes touching links" do
    link = CardLink.create!(from_card: cards(:logo), to_card: cards(:layout), link_type: "decomposes_into")

    assert_difference -> { CardLink.count }, -1 do
      cards(:layout).destroy!
    end
    assert_not CardLink.exists?(link.id)
  end
end
