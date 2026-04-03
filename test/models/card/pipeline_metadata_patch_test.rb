require "test_helper"

class Card::PipelineMetadataPatchTest < ActiveSupport::TestCase
  setup do
    Current.session = sessions(:david)
  end

  test "metadata_patch shallow merges metadata, deletes extension subkeys, and bumps the version" do
    card = cards(:logo)
    card.update!(
      pipeline_metadata: {
        "wave" => 1,
        "reviewer_agent" => "claude",
        "extensions" => {
          "keep" => "yes",
          "drop" => "soon"
        }
      },
      metadata_version: 5
    )

    assert card.metadata_patch(
      {
        "commit_hash" => "abc123",
        "reviewer_agent" => nil,
        "extensions" => {
          "drop" => nil,
          "add" => "new"
        }
      },
      expected_version: 5
    )

    card.reload
    assert_equal 6, card.metadata_version
    assert_equal(
      {
        "wave" => 1,
        "reviewer_agent" => nil,
        "commit_hash" => "abc123",
        "extensions" => {
          "keep" => "yes",
          "add" => "new"
        }
      },
      card.pipeline_metadata
    )
  end

  test "metadata_patch returns false when the version is stale" do
    card = cards(:logo)
    card.update!(pipeline_metadata: { "wave" => 1 }, metadata_version: 3)

    assert_not card.metadata_patch({ "commit_hash" => "abc123" }, expected_version: 2)

    card.reload
    assert_equal 3, card.metadata_version
    assert_equal({ "wave" => 1 }, card.pipeline_metadata)
  end
end
