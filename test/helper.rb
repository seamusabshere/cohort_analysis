require 'rubygems'
require 'bundler'
Bundler.setup
require 'test/unit'
$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'cohort_scope'

if ::Bundler.definition.specs['ruby-debug19'].first or ::Bundler.definition.specs['ruby-debug'].first
  require 'ruby-debug'
end
  
class Test::Unit::TestCase
end

# require 'logger'
# ActiveRecord::Base.logger = Logger.new($stdout)

ActiveRecord::Base.establish_connection(
  'adapter' => 'mysql2',
  'database' => 'test_cohort_scope',
  'username' => 'root',
  'password' => 'password'
)

c = ActiveRecord::Base.connection
c.create_table 'citizens', :force => true do |t|
  t.date 'birthdate'
  t.string 'favorite_color'
  t.integer 'teeth'
end
c.create_table 'houses', :force => true do |t|
  t.string 'period_id'
  t.string 'address'
  t.integer 'storeys'
end
c.create_table 'periods', :force => true, :id => false do |t|
  t.string 'name'
end
c.execute "ALTER TABLE periods ADD PRIMARY KEY (name)"
c.create_table 'styles', :force => true, :id => false do |t|
  t.string 'name'
  t.string 'period_id'
end
c.execute "ALTER TABLE styles ADD PRIMARY KEY (name)"
c.create_table 'residents', :force => true do |t|
  t.integer 'house_id'
  t.string 'name'
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
  c = Citizen.new; c.birthdate = birthdate; c.favorite_color = favorite_color; c.teeth = teeth; c.save!
end

class Period < ActiveRecord::Base
  set_primary_key :name
  has_many :styles
  has_many :houses
  
  # hack to make sure rails doesn't protect the foreign key columns
  self._protected_attributes = BlackList.new
end

class Style < ActiveRecord::Base
  set_primary_key :name
  extend CohortScope
  self.minimum_cohort_size = 3
  belongs_to :period
  has_many :houses, :through => :period, :foreign_key => 'name'
  
  # hack to make sure rails doesn't protect the foreign key columns
  self._protected_attributes = BlackList.new
end

class House < ActiveRecord::Base
  belongs_to :period
  has_many :styles, :through => :period
  has_one :resident
end

class Resident < ActiveRecord::Base
  belongs_to :house
end

p1 = Period.new; p1.name = 'arts and crafts'; p1.save!
p2 = Period.new; p2.name = 'victorian'; p2.save!
s1 = Style.new; s1.period = p1; s1.name = 'classical revival'; s1.save!
s2 = Style.new; s2.period = p1; s2.name = 'gothic'; s2.save!
s3 = Style.new; s3.period = p1; s3.name = 'art deco'; s3.save!
s4 = Style.new; s4.period = p2; s4.name = 'stick-eastlake'; s4.save!
s5 = Style.new; s5.period = p2; s5.name = 'queen anne'; s5.save!
h1 = House.create! :period => p1, :address => '123 Maple', :storeys => 1
h2 = House.create! :period => p1, :address => '223 Walnut', :storeys => 2
h3 = House.create! :period => p2, :address => '323 Pine', :storeys => 2
Resident.create! :house => h1, :name => 'Bob'
Resident.create! :house => h2, :name => 'Rob'
Resident.create! :house => h3, :name => 'Gob'
