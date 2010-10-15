require 'helper'

class TestCohort < Test::Unit::TestCase
  def setup
    Citizen.minimum_cohort_size = 3
    @date_range = (Date.parse('1980-01-01')..Date.parse('1990-01-01'))
  end

  def style
    @style ||= Style.find_by_period 'arts and crafts'
  end

  context '.sanitize_constraints' do
    should 'remove nil constraints' do
      constraints = CohortScope::Cohort.sanitize_constraints Style, :eh => :tu, :bru => :te, :caesar => nil
      assert_does_not_contain constraints.keys, :caesar
    end
    should 'keep normal constraints' do
      constraints = CohortScope::Cohort.sanitize_constraints Style, :eh => :tu, :bru => :te, :caesar => nil
      assert_equal :tu, constraints[:eh]
    end
    should 'include constraints that are models' do
      gob = Resident.find_by_name 'Gob'
      constraints = CohortScope::Cohort.sanitize_constraints House, :resident => gob
      assert_equal gob.house_id, constraints[:house_id]
    end
    should 'include constraints that are models not related by primary key' do
      constraints = CohortScope::Cohort.sanitize_constraints House, :style => style
      assert_equal 'arts and crafts', constraints['period']
    end
  end

  context '.association_primary_key' do
    should 'include constraints that are models related by a primary key' do
      gob = Resident.find_by_name('Gob')
      key = CohortScope::Cohort.association_primary_key Resident, :house
      assert_equal 'resident_id', key
    end
    should 'include constraints that are models related by a non-primary key' do
      key = CohortScope::Cohort.association_primary_key House, :style
      assert_equal 'period', key
    end
  end
end
