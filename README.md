# Spanner::Translator

A quick-and-dirty [Rubocop::AST](https://github.com/rubocop/rubocop-ast) based `create_table` Ruby source rewriting translator to facilitate migration from MySQL to Google Cloud Spanner.

Not intended to be a generally-useful gem, but available for use / fork as needed.

## Installation

Add the gem as a `git:` dependency to your Gemfile:

```ruby
group :development do
  gem 'spanner-translator', github: 'abachman/spanner-translator', branch: 'main', require: false
end
```

## Usage

If you're in a Rails project, configure the library and use the `spanner:translate` Rake task:


```ruby
# config/initializers/spanner_translator.rb

if Rails.env.development?
  require 'spanner/translator'

  Spanner::Translator.configure do |config|
    config.default_primary_keys = [:related_table_id, :id]
    config.db_schema = Rails.root.join('db/schema.rb')
  end
end
```

```sh
$ bundle exec rake spanner:translate[smalls]
```

Or in any project, call the library from a script:

```ruby
# frozen_string_literal: true

require 'spanner/translator'

Spanner::Translator.configure do |config|
  config.default_primary_keys = [:id]
end

source = <<~RUBY
  create_table "smalls", id: { type: :bigint, unsigned: true, default: nil } do |t|
    t.string "name", null: false
    t.index ["name"], name: "index_smalls_on_name", order: { name: :asc }
  end
RUBY

puts Spanner::Translator::CLI.process_code!(source)
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

Run the test suite with `bundle exec rspec`.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/abachman/spanner-translator. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/abachman/spanner-translator/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Spanner::Translator project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/abachman/spanner-translator/blob/main/CODE_OF_CONDUCT.md).
