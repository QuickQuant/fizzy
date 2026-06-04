require "test_helper"

class Cards::LinksControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as :kevin
  end

  test "create as JSON" do
    from_card = cards(:logo)
    to_card = cards(:layout)

    assert_difference -> { CardLink.count }, +1 do
      post card_links_path(from_card), params: { link: { to_card_number: to_card.number, link_type: "decomposes_into" } }, as: :json
    end

    assert_response :created
    assert_equal from_card.number, @response.parsed_body["from_card_number"]
    assert_equal to_card.number, @response.parsed_body["to_card_number"]
    assert_equal "decomposes_into", @response.parsed_body["link_type"]
  end

  test "create is idempotent as JSON" do
    from_card = cards(:logo)
    to_card = cards(:layout)

    assert_difference -> { CardLink.count }, +1 do
      2.times do
        post card_links_path(from_card), params: { link: { to_card_number: to_card.number, link_type: "decomposes_into" } }, as: :json
        assert_response :created
      end
    end
  end

  test "index filters outbound links as JSON" do
    from_card = cards(:logo)
    decomposition_target = cards(:layout)
    verification_target = cards(:text)
    CardLink.create!(from_card: from_card, to_card: decomposition_target, link_type: "decomposes_into")
    CardLink.create!(from_card: from_card, to_card: verification_target, link_type: "verifies_at_level")

    get card_links_path(from_card), params: { link_type: "decomposes_into" }, as: :json

    assert_response :success
    assert_equal [ decomposition_target.number ], @response.parsed_body.map { |link| link["to_card_number"] }
  end

  test "index filters inbound links as JSON" do
    parent = cards(:logo)
    child = cards(:layout)
    CardLink.create!(from_card: parent, to_card: child, link_type: "decomposes_into")

    get card_links_path(child), params: { link_type: "decomposes_into", direction: "inbound" }, as: :json

    assert_response :success
    assert_equal [ parent.number ], @response.parsed_body.map { |link| link["from_card_number"] }
  end

  test "destroy as JSON" do
    from_card = cards(:logo)
    link = CardLink.create!(from_card: from_card, to_card: cards(:layout), link_type: "decomposes_into")

    assert_difference -> { CardLink.count }, -1 do
      delete card_link_path(from_card, link), as: :json
    end

    assert_response :no_content
    assert_not CardLink.exists?(link.id)
  end

  test "create rejects inaccessible target" do
    assert_no_difference -> { CardLink.count } do
      post card_links_path(cards(:logo)), params: { link: { to_card_number: 99_999, link_type: "decomposes_into" } }, as: :json
    end

    assert_response :not_found
  end
end
