require 'rubygems'
require 'bundler/setup'

require 'minitest/spec'
require 'minitest/autorun'
require 'minitest/reporters'
MiniTest::Unit.runner = MiniTest::SuiteRunner.new
MiniTest::Unit.runner.reporters << MiniTest::Reporters::SpecReporter.new

require 'factory_girl'

require 'active_record'
require 'active_record_inline_schema'

require 'cohort_analysis'

if ::Bundler.definition.specs['debugger'].first
  require 'debugger'
elsif ::Bundler.definition.specs['ruby-debug'].first
  require 'ruby-debug'
end

# require 'logger'
# ActiveRecord::Base.logger = Logger.new($stdout)

ActiveRecord::Base.establish_connection(:adapter => "sqlite3", :database => ":memory:")

Arel::Table.engine = ActiveRecord::Base

# https://gist.github.com/1560208 - shared examples in minispec

MiniTest::Spec.class_eval do
  # start transaction
  before do
    # activerecord-3.2.3/lib/active_record/fixtures.rb
    @fixture_connections = ActiveRecord::Base.connection_handler.connection_pools.values.map(&:connection)
    @fixture_connections.each do |connection|
      connection.increment_open_transactions
      connection.transaction_joinable = false
      connection.begin_db_transaction
    end
  end

  # rollback
  after do
    @fixture_connections.each do |connection|
      if connection.open_transactions != 0
        connection.rollback_db_transaction
        connection.decrement_open_transactions
      end
    end
    @fixture_connections.clear
    ActiveRecord::Base.clear_active_connections!
  end

  def self.shared_examples
    @shared_examples ||= {}
  end
end

module MiniTest::Spec::SharedExamples
  def shared_examples_for(desc, &block)
    MiniTest::Spec.shared_examples[desc] = block
  end

  def it_behaves_like(desc)
    self.instance_eval do
      MiniTest::Spec.shared_examples[desc].call
    end
  end
end

Object.class_eval { include(MiniTest::Spec::SharedExamples) }
