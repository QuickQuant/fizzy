class AddPipelineMetadataToCards < ActiveRecord::Migration[8.2]
  def up
    add_column :cards, :pipeline_metadata, :json, default: pipeline_metadata_default, null: false
    add_column :cards, :metadata_version, :bigint, default: 0, null: false

    change_table :cards, bulk: true do |t|
      t.virtual :pipeline_card_type, type: :string, as: pipeline_metadata_extract("card_type")
      t.virtual :pipeline_session_id, type: :string, as: pipeline_metadata_extract("session_id")
      t.virtual :pipeline_parent_session_id, type: :string, as: pipeline_metadata_extract("parent_session_id")
      t.virtual :pipeline_task_id, type: :string, as: pipeline_metadata_extract("task_id")
    end

    add_index :cards, :pipeline_card_type
    add_index :cards, :pipeline_session_id
    add_index :cards, :pipeline_parent_session_id
    add_index :cards, :pipeline_task_id
  end

  def down
    remove_index :cards, :pipeline_task_id
    remove_index :cards, :pipeline_parent_session_id
    remove_index :cards, :pipeline_session_id
    remove_index :cards, :pipeline_card_type

    remove_column :cards, :pipeline_task_id
    remove_column :cards, :pipeline_parent_session_id
    remove_column :cards, :pipeline_session_id
    remove_column :cards, :pipeline_card_type
    remove_column :cards, :metadata_version
    remove_column :cards, :pipeline_metadata
  end

  private
    def pipeline_metadata_default
      if Fizzy.db_adapter.sqlite?
        {}
      else
        -> { "(json_object())" }
      end
    end

    def pipeline_metadata_extract(key)
      if Fizzy.db_adapter.sqlite?
        "json_extract(pipeline_metadata, '$.#{key}')"
      else
        "json_unquote(json_extract(`pipeline_metadata`, _utf8mb4'$.#{key}'))"
      end
    end
end
