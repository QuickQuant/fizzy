require "test_helper"

class Card::PipelineMetadataTest < ActiveSupport::TestCase
  setup do
    Current.session = sessions(:david)
    Card.reset_column_information
  end

  test "cards table exposes pipeline metadata columns and indexes" do
    columns = Card.columns_hash
    card = Card.create!(title: "Default metadata", board: boards(:writebook), creator: users(:david))

    assert_equal :json, columns.fetch("pipeline_metadata").type
    assert_equal({}, card.reload.pipeline_metadata)
    assert_equal 0, card.metadata_version

    %w[pipeline_card_type pipeline_session_id pipeline_parent_session_id pipeline_task_id].each do |name|
      column = columns.fetch(name)
      assert_predicate column, :virtual?

      if column.respond_to?(:virtual_stored?)
        assert_not_predicate column, :virtual_stored?
      else
        assert_match(/\bVIRTUAL\b/, column.extra)
      end
    end

    indexed_columns = Card.connection.indexes(:cards).map(&:columns)
    assert_includes indexed_columns, [ "pipeline_card_type" ]
    assert_includes indexed_columns, [ "pipeline_session_id" ]
    assert_includes indexed_columns, [ "pipeline_parent_session_id" ]
    assert_includes indexed_columns, [ "pipeline_task_id" ]
  end

  test "pipeline session queries use the generated column index" do
    board = boards(:writebook)
    creator = users(:david)

    10.times do |n|
      Card.create!(
        title: "Pipeline #{n}",
        board: board,
        creator: creator,
        pipeline_metadata: {
          "card_type" => "task",
          "session_id" => "sess-123",
          "parent_session_id" => "sess-parent",
          "task_id" => "T#{n}"
        }
      )
    end

    200.times do |n|
      Card.create!(
        title: "Noise #{n}",
        board: board,
        creator: creator,
        pipeline_metadata: {
          "card_type" => "task",
          "session_id" => "noise-#{n}",
          "parent_session_id" => "sess-parent",
          "task_id" => "N#{n}"
        }
      )
    end

    assert_equal 10, Card.where(pipeline_session_id: "sess-123").count

    explain_sql =
      if Fizzy.db_adapter.sqlite?
        "EXPLAIN QUERY PLAN SELECT * FROM cards WHERE pipeline_session_id = #{Card.connection.quote("sess-123")}"
      else
        "EXPLAIN SELECT * FROM cards WHERE pipeline_session_id = #{Card.connection.quote("sess-123")}"
      end

    plan_rows = Card.connection.exec_query(explain_sql).to_a

    if Fizzy.db_adapter.sqlite?
      detail = plan_rows.map { |row| row["detail"] }.compact.join(" ")
      assert_match(/index_cards_on_pipeline_session_id/i, detail)
    else
      assert_equal "index_cards_on_pipeline_session_id", plan_rows.first["key"]
      assert_not_equal "ALL", plan_rows.first["type"]
    end
  end
end
