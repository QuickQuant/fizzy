class AddStepGroupToSteps < ActiveRecord::Migration[8.2]
  def change
    add_column :steps, :step_group, :string
  end
end
