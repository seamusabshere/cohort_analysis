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

require 'arel/nodes/table_alias' # strange

if ::Bundler.definition.specs['debugger'].first
  require 'debugger'
elsif ::Bundler.definition.specs['ruby-debug'].first
  require 'ruby-debug'
end

# require 'logger'
# ActiveRecord::Base.logger = Logger.new($stdout)

case ENV['DATABASE']
when /mysql/i
  bin = ENV['TEST_MYSQL_BIN'] || 'mysql'
  username = ENV['TEST_MYSQL_USERNAME'] || 'root'
  password = ENV['TEST_MYSQL_PASSWORD'] || 'password'
  database = ENV['TEST_MYSQL_DATABASE'] || 'test_cohort_analysis'
  cmd = "#{bin} -u #{username} -p#{password}"
  `#{cmd} -e 'show databases'`
  unless $?.success?
    $stderr.puts "Skipping mysql tests because `#{cmd}` doesn't work"
    exit 0
  end
  system %{#{cmd} -e "drop database #{database}"}
  system %{#{cmd} -e "create database #{database}"}
  ActiveRecord::Base.establish_connection(
    'adapter' => (RUBY_PLATFORM == 'java' ? 'mysql' : 'mysql2'),
    'encoding' => 'utf8',
    'database' => database,
    'username' => username,
    'password' => password
  )
when /postgr/i
  createdb_bin = ENV['TEST_CREATEDB_BIN'] || 'createdb'
  dropdb_bin = ENV['TEST_DROPDB_BIN'] || 'dropdb'
  username = ENV['TEST_POSTGRES_USERNAME'] || `whoami`.chomp
  # password = ENV['TEST_POSTGRES_PASSWORD'] || 'password'
  database = ENV['TEST_POSTGRES_DATABASE'] || 'test_cohort_analysis'
  system %{#{dropdb_bin} #{database}}
  system %{#{createdb_bin} #{database}}
  ActiveRecord::Base.establish_connection(
    'adapter' => 'postgresql',
    'encoding' => 'utf8',
    'database' => database,
    'username' => username
    # 'password' => password
  )
when /sqlite/i
  ActiveRecord::Base.establish_connection(:adapter => "sqlite3", :database => ":memory:")
else
  raise "don't know how to test against #{ENV['DATABASE']}"
end

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
