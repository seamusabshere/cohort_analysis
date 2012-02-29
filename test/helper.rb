require 'rubygems'
require 'bundler/setup'

require 'minitest/spec'
require 'minitest/autorun'
require 'minitest/reporters'
MiniTest::Unit.runner = MiniTest::SuiteRunner.new
MiniTest::Unit.runner.reporters << MiniTest::Reporters::SpecReporter.new

require 'factory_girl'

$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'cohort_analysis'

if ::Bundler.definition.specs['ruby-debug19'].first or ::Bundler.definition.specs['ruby-debug'].first
  require 'ruby-debug'
end

# require 'logger'
# ActiveRecord::Base.logger = Logger.new($stdout)

ActiveRecord::Base.establish_connection(
  'adapter' => 'mysql2',
  'database' => 'test_cohort_analysis',
  'username' => 'root',
  'password' => 'password'
)
