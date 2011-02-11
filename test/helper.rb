require 'rubygems'
require 'bundler'
Bundler.setup
require 'test/unit'
require 'shoulda'
require 'logger'
$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'cohort_scope'

class Test::Unit::TestCase
end

$logger = Logger.new 'test/test.log' #STDOUT
ActiveSupport::Notifications.subscribe do |*args|
  event = ActiveSupport::Notifications::Event.new(*args)
  $logger.debug "#{event.payload[:name]} (#{event.duration}) #{event.payload[:sql]}"
end

ActiveRecord::Base.establish_connection(
  'adapter' => 'sqlite3',
  'database' => ':memory:'
)

ActiveRecord::Schema.define(:version => 20090819143429) do
  create_table 'citizens', :force => true do |t|
    t.date 'birthdate'
    t.string 'favorite_color'
    t.integer 'teeth'
  end
  create_table 'houses', :force => true do |t|
    t.string 'period'
    t.string 'address'
    t.integer 'storeys'
  end
  create_table 'styles', :force => true do |t|
    t.string 'period'
    t.string 'name'
  end
  create_table 'residents', :force => true do |t|
    t.integer 'house_id'
    t.string 'name'
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

class Style < ActiveRecord::Base
  extend CohortScope
  self.minimum_cohort_size = 3
  has_many :houses
end
class House < ActiveRecord::Base
  belongs_to :style, :foreign_key => 'period', :primary_key => 'period'
  has_one :resident
end
class Resident < ActiveRecord::Base
  has_one :house
end

Style.create! :period => 'arts and crafts', :name => 'classical revival'
Style.create! :period => 'arts and crafts', :name => 'gothic'
Style.create! :period => 'arts and crafts', :name => 'art deco'
Style.create! :period => 'victorian', :name => 'stick-eastlake'
Style.create! :period => 'victorian', :name => 'queen anne'
h1 = House.create! :period => 'arts and crafts', :address => '123 Maple', :storeys => 1
h2 = House.create! :period => 'arts and crafts', :address => '223 Walnut', :storeys => 2
h3 = House.create! :period => 'victorian', :address => '323 Pine', :storeys => 2
Resident.create! :house => h1, :name => 'Bob'
Resident.create! :house => h2, :name => 'Rob'
Resident.create! :house => h3, :name => 'Gob'
