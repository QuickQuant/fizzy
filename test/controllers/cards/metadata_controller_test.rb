require "test_helper"

class Cards::MetadataControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as :kevin
  end

  test "update merges metadata and increments metadata_version" do
    card = cards(:logo)
    card.update!(
      pipeline_metadata: {
        "wave" => 1,
        "extensions" => {
          "keep" => "yes",
          "drop" => "soon"
        }
      },
      metadata_version: 0
    )

    patch card_metadata_path(card),
      params: {
        pipeline_metadata: {
          card_type: "task",
          reviewer_agent: nil,
          extensions: {
            drop: nil,
            add: "new"
          }
        }
      },
      headers: { "If-Match-Metadata-Version" => "0" },
      as: :json

    assert_response :success

    body = @response.parsed_body
    assert_equal "task", body.dig("pipeline_metadata", "card_type")
    assert_equal 1, body.dig("pipeline_metadata", "wave")
    assert_nil body.dig("pipeline_metadata", "reviewer_agent")
    assert_equal({ "keep" => "yes", "add" => "new" }, body.dig("pipeline_metadata", "extensions"))
    assert_equal 1, body["metadata_version"]

    card.reload
    assert_equal body["pipeline_metadata"], card.pipeline_metadata
    assert_equal 1, card.metadata_version
  end

  test "update requires If-Match-Metadata-Version header" do
    card = cards(:logo)
    card.update!(pipeline_metadata: { "wave" => 1 }, metadata_version: 1)

    patch card_metadata_path(card),
      params: { pipeline_metadata: { card_type: "task" } },
      as: :json

    assert_response :precondition_required
    assert_equal({ "wave" => 1 }, card.reload.pipeline_metadata)
    assert_equal 1, card.metadata_version
  end

  test "update returns conflict on stale metadata_version" do
    card = cards(:logo)
    card.update!(pipeline_metadata: { "wave" => 1 }, metadata_version: 3)

    patch card_metadata_path(card),
      params: { pipeline_metadata: { card_type: "task" } },
      headers: { "If-Match-Metadata-Version" => "2" },
      as: :json

    assert_response :conflict
    assert_equal(
      {
        "error" => "METADATA_VERSION_CONFLICT",
        "expected" => 2,
        "actual" => 3
      },
      @response.parsed_body
    )
    assert_equal({ "wave" => 1 }, card.reload.pipeline_metadata)
  end
end
