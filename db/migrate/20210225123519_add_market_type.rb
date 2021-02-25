# frozen_string_literal: true

class AddMarketType < ActiveRecord::Migration[5.2]
  class LegacyMarket < ActiveRecord::Base
  end

  def change
    rename_table :markets, :legacy_markets

    create_table :markets do |t|
      t.string 'symbol', limit: 20, null: false
      t.string 'type', default: 'spot', null: false
      t.string 'base_unit', limit: 10, null: false
      t.string 'quote_unit', limit: 10, null: false
      t.bigint 'engine_id', null: false
      t.integer 'amount_precision', limit: 1, default: 4, null: false
      t.integer 'price_precision', limit: 1, default: 4, null: false
      t.decimal 'min_price', precision: 32, scale: 16, default: '0.0', null: false
      t.decimal 'max_price', precision: 32, scale: 16, default: '0.0', null: false
      t.decimal 'min_amount', precision: 32, scale: 16, default: '0.0', null: false
      t.integer 'position', null: false
      t.json 'data'
      t.string 'state', limit: 32, default: 'enabled', null: false
      t.timestamps
    end

    add_index(:markets, %i[base_unit quote_unit type], unique: true)
    add_index(:markets, %i[symbol type], unique: true)
    add_index(:markets, 'base_unit')
    add_index(:markets, 'position')
    add_index(:markets, 'quote_unit')
    add_index(:markets, 'engine_id')

    LegacyMarket.find_each do |market|
      market_attrs = market.attributes
      market_attrs['symbol'] = market_attrs['id']
      Market.create!(market_attrs.except('id', 'created_at', 'updated_at'))
    end

    drop_table :legacy_markets

    add_column(:orders, :market_type, :string, null: false, default: 'spot', after: 'market_id')
    remove_index(:orders, %w[type market_id]) if index_exists?(:orders, %w[type market_id])
    remove_index(:orders, %w[type state market_id]) if index_exists?(:orders, %w[type state market_id])
    add_index(:orders, %w[type market_id market_type]) unless index_exists?(:orders, %w[type market_id market_type])
    add_index(:orders, %w[type state market_id market_type]) unless index_exists?(:orders, %w[type state market_id market_type])


    add_column(:trades, :market_type, :string, null: false, default: 'spot', after: 'market_id')
    remove_index(:trades, 'maker_id') if index_exists?(:orders, 'market_id')
    remove_index(:trades, 'taker_id') if index_exists?(:orders, 'taker_id')
    remove_index(:trades, %w[market_id created_at]) if index_exists?(:orders, %w[market_id created_at])
    add_index(:trades, %w[maker_id market_type]) unless index_exists?(:orders, %w[maker_id market_type])
    add_index(:trades, %w[taker_id market_type]) unless index_exists?(:orders, %w[taker_id market_type])
    add_index(:trades, %w[maker_id market_type created_at]) unless index_exists?(:orders, %w[maker_id market_type created_at])
  end
end
