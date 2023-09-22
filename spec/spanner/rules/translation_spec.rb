# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Spanner::Translator::Rules::Translation" do
  let(:mock_rewriter) { instance_double("Parser::Source::TreeRewriter") }

  RSpec.shared_examples "a rule" do |rule_class|
    it "is a subclass of Spanner::Translator::Rules::BaseRule" do
      expect(rule_class).to be < Spanner::Translator::Rules::BaseRule
    end

    it "implements #on_send" do
      expect(rule_class.new(mock_rewriter)).to respond_to(:on_send)
    end

    it "translates a MySQL AST to a Spanner AST" do
      actual = Spanner::Translator::CLI.process_rule(rule_class, mysql_source)
      expect(actual).to eq(spanner_source)
    end
  end

  context "AddCommittedAtTimestamp" do
    let(:mysql_source) do
      <<~RUBY
        create_table "users", force: :cascade do |t|
          t.string "name"
          t.index ["name"], name: "index_users_on_name"
        end
      RUBY
    end

    let(:spanner_source) do
      <<~RUBY
        create_table "users", force: :cascade do |t|
          t.string "name"
          t.time "committed_at", null: false, allow_commit_timestamp: true
          t.index ["name"], name: "index_users_on_name"
        end
      RUBY
    end

    it_behaves_like "a rule", Spanner::Translator::Rules::Translation::AddCommittedAtTimestamp
  end

  context "AddIdColumn" do
    let(:mysql_source) do
      <<~RUBY
        create_table "users", force: :cascade do |t|
          t.string "name"
        end
      RUBY
    end

    let(:spanner_source) do
      <<~RUBY
        create_table "users", force: :cascade do |t|
          t.integer "id", limit: 8, null: false
          t.string "name"
        end
      RUBY
    end

    it_behaves_like "a rule", Spanner::Translator::Rules::Translation::AddIdColumn
  end

  context "AddIndexOptions" do
    let(:mysql_source) do
      <<~RUBY
        t.bigint "customer_id", null: false, unsigned: true
        t.bigint "account_id", null: false, unsigned: true
        t.string "poster_url"
        t.string "currency", limit: 3
        t.datetime "updated_at", null: false
        t.index ["account_id"], name: "index_merchant_acquisitions_on_account_id", unique: true
        t.index ["account_id", "currency"], name: "account_id_and_currency", unique: true
        t.index ["account_id", "poster_url"], name: "account_id_and_poster_url"
        t.index ["account_id", "customer_id"], name: "account_id_and_customer_id"
        t.index ["customer_id"]
        t.index ["customer_id", "updated_at"], name: "index_merchant_acquisitions_on_customer_id_and_updated_at"
      RUBY
    end

    let(:spanner_source) do
      <<~RUBY
        t.bigint "customer_id", null: false, unsigned: true
        t.bigint "account_id", null: false, unsigned: true
        t.string "poster_url"
        t.string "currency", limit: 3
        t.datetime "updated_at", null: false
        t.index ["account_id"], name: "index_merchant_acquisitions_on_account_id", unique: true, order: { account_id: :asc }
        t.index ["account_id", "currency"], name: "account_id_and_currency", unique: true, order: { account_id: :asc, currency: :asc }, null_filtered: true
        t.index ["account_id", "poster_url"], name: "account_id_and_poster_url", order: { account_id: :asc, poster_url: :asc }
        t.index ["account_id", "customer_id"], name: "account_id_and_customer_id", order: { account_id: :asc, customer_id: :asc }
        t.index ["customer_id"], order: { customer_id: :asc }
        t.index ["customer_id", "updated_at"], name: "index_merchant_acquisitions_on_customer_id_and_updated_at", order: { customer_id: :asc, updated_at: :desc }
      RUBY
    end

    it_behaves_like "a rule", Spanner::Translator::Rules::Translation::AddIndexOptions
  end
end
