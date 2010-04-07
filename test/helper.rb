require 'rubygems'
require 'test/unit'
require 'shoulda'
require 'ruby-debug'
require 'logger'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'cohort_scope'

class Test::Unit::TestCase
end

$logger = Logger.new STDOUT #'test/test.log'
ActiveSupport::Notifications.subscribe do |*args|
  event = ActiveSupport::Notifications::Event.new(*args)
  $logger.debug "#{event.payload[:name]} (#{event.duration}) #{event.payload[:sql]}"
end

ActiveRecord::Base.establish_connection(
  'adapter' => 'mysql',
  'database' => 'cohort_scope_test',
  'username' => 'root',
  'password' => ''
)

ActiveRecord::Schema.define(:version => 20090819143429) do
  create_table 'citizens', :force => true do |t|
    t.date 'birthdate'
    t.string 'favorite_color'
    t.integer 'teeth'
  end
end

class Citizen < ActiveRecord::Base
  extend CohortScope
  self.minimum_cohort_size = 3
  validates_presence_of :birthdate
end

[
  [ '1982-09-29', 'blue', 31 ],
  [ '1954-12-20', 'heliotrope', 32 ],
  [ '1983-10-28', 'green', 24 ],
  [ '1984-02-14', 'firetruck red', 27 ],
  [ '1955-07-21', 'blue', 27 ],
  [ '1983-06-08', 'purple', 42 ],
  [ '1982-04-27', 'black', 24 ],
  [ '1984-07-16', 'blue', 29 ],
  [ '1975-02-18', 'green', 18 ],
  [ '1988-02-01', nil, 31 ],
  [ '1985-03-02', nil, 27 ],
  [ '1982-05-01', nil, 28 ]
].each do |birthdate, favorite_color, teeth|
  Citizen.create! :birthdate => birthdate, :favorite_color => favorite_color, :teeth => teeth
end
