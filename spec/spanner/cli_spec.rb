# frozen_string_literal: true

require "spec_helper"
require "spanner/translator"

RSpec.describe Spanner::Translator::CLI do
  let(:mysql_create_table) do
    <<~RUBY
      create_table "merchant_acquisitions", id: { type: :bigint, unsigned: true, default: nil }, charset: "utf8mb3", collation: "utf8mb3_unicode_ci", force: :cascade do |t|
        t.bigint "customer_id", null: false, unsigned: true
        t.bigint "account_id", null: false, unsigned: true
        t.integer "cost_in_cents"
        t.string "currency", limit: 3
        t.datetime "created_at", null: false
        t.datetime "updated_at", null: false
        t.timestamp "deleted_at"
        t.column "relationship", "enum('CHILD','parent')", limit: ["CHILD", "parent"], default: "CHILD", null: false
        t.column "status", "enum('open', 'closed')", limit: ["open", "closed"]
        t.index ["account_id"], name: "index_merchant_acquisitions_on_account_id", unique: true
        t.index ["customer_id"], name: "index_merchant_acquisitions_on_customer_id"
        t.index ["customer_id", "created_at"], name: "index_merchant_acquisitions_on_customer_id_and_created_at"
        t.index ["customer_id", "updated_at"], name: "index_merchant_acquisitions_on_customer_id_and_updated_at"
      end
    RUBY
  end

  let(:expected) do
    <<~RUBY.chomp
      create_table "merchant_acquisitions", primary_key: [:customer_id, :id], force: :cascade do |t|
        t.integer "id", limit: 8, null: false
        t.integer "customer_id", limit: 8, null: false
        t.integer "account_id", limit: 8, null: false
        t.integer "cost_in_cents"
        t.string "currency", limit: 3
        t.time "created_at", null: false
        t.time "updated_at", null: false
        t.time "deleted_at"
        t.string "relationship", null: false, default: "CHILD", limit: 6
        t.string "status", limit: 6
        t.time "committed_at", null: false, allow_commit_timestamp: true
        t.index ["account_id"], name: "index_merchant_acquisitions_on_account_id", unique: true, order: { account_id: :asc }
        t.index ["customer_id"], name: "index_merchant_acquisitions_on_customer_id", order: { customer_id: :asc }
        t.index ["customer_id", "created_at"], name: "index_merchant_acquisitions_on_customer_id_and_created_at", order: { customer_id: :asc, created_at: :desc }
        t.index ["customer_id", "updated_at"], name: "index_merchant_acquisitions_on_customer_id_and_updated_at", order: { customer_id: :asc, updated_at: :desc }
        t.check_constraint "relationship IN ('CHILD', 'parent')", name: "chk_rails_enum_merchant_acquisitions_relationship"
        t.check_constraint "status IN ('', 'open', 'closed')", name: "chk_rails_enum_merchant_acquisitions_status"
      end
    RUBY
  end

  let(:no_index_table) do
    <<~RUBY
      create_table "no_index", id: { type: :bigint, unsigned: true, default: nil } do |t|
        t.string "name"
      end
    RUBY
  end

  let(:small_table) do
    <<~RUBY
      create_table "smalls", id: { type: :bigint, unsigned: true, default: nil } do |t|
        t.string "name", null: false
        t.index ["name"], name: "index_smalls_on_name", order: { name: :asc }
      end
    RUBY
  end

  let(:small_table_expected) do
    <<~RUBY.chomp
      create_table "smalls", primary_key: [:customer_id, :id], force: :cascade do |t|
        t.integer "id", limit: 8, null: false
        t.string "name", null: false
        t.time "committed_at", null: false, allow_commit_timestamp: true
        t.index ["name"], name: "index_smalls_on_name", order: { name: :asc }
      end
    RUBY
  end

  before do
    Spanner::Translator.configure do |config|
      config.default_primary_keys = %i[customer_id id]
    end
  end

  describe ".process_code" do
    it "converts mysql create_table statements" do
      actual = described_class.process_code(mysql_create_table)
      expect(actual.chomp).to eq(expected)
    end

    it "adds id and committed_at columns to tables" do
      actual = described_class.process_code(small_table)
      expect(actual.chomp).to eq(small_table_expected)
    end
  end

  describe ".process_code!" do
    it "raises an error if the table has no index" do
      expect do
        described_class.process_code!(no_index_table)
      end.to raise_error(StandardError, /table has no index/)
    end
  end
end
