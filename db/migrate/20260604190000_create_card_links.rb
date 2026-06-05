class CreateCardLinks < ActiveRecord::Migration[8.2]
  def change
    create_table :card_links, id: :uuid do |t|
      t.uuid :account_id, null: false
      t.uuid :from_card_id, null: false
      t.uuid :to_card_id, null: false
      t.string :link_type, null: false
      t.timestamps
    end

    add_index :card_links, [ :account_id, :from_card_id, :link_type ],
      name: "index_card_links_on_account_from_type"
    add_index :card_links, [ :account_id, :to_card_id, :link_type ],
      name: "index_card_links_on_account_to_type"
    add_index :card_links, [ :from_card_id, :to_card_id, :link_type ],
      unique: true,
      name: "index_card_links_on_from_to_type_unique"
  end
end
