class AddAccountType < ActiveRecord::Migration[5.2]
  def change
    add_column :accounts, :type, :string, default: :spot, null: false, after: :currency_id
  end
end
