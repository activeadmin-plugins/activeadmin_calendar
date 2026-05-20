# frozen_string_literal: true

ActiveRecord::Schema.define(version: 1) do
  create_table :payments, force: true do |t|
    t.decimal  :amount, precision: 10, scale: 2, null: false
    t.string   :card_type, null: false
    t.datetime :paid_at, null: false
    t.timestamps
  end
  add_index :payments, :paid_at

  create_table :bookings, force: true do |t|
    t.string  :guest_name,  null: false
    t.integer :room_number, null: false
    t.date    :check_in,    null: false
    t.date    :check_out,   null: false
    t.timestamps
  end
  add_index :bookings, [:check_in, :check_out]
end
