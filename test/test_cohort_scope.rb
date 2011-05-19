require 'helper'

class TestCohortScope < Test::Unit::TestCase
  def setup
    Citizen.minimum_cohort_size = 3
    @date_range = (Date.parse('1980-01-01')..Date.parse('1990-01-01'))
  end

  def test_001_has_sane_associations
    assert Period.first.styles.first
    assert Period.first.houses.first
    assert Style.first.period
    assert Style.first.houses.first
    assert House.first.period
    assert House.first.styles.first
    assert House.all.any? { |h| h.resident }
    assert House.joins(:styles).where(:styles => { :name => [style] }).first.styles.include?(style)
    assert Style.joins(:houses).where(:houses => { :id => [house1] }).first
  end
  
  # confusing as hell because houses have styles according to periods, which is not accurate
  def test_002a_complicated_cohorts_with_joins
    assert_equal 3, Style.joins(:houses).big_cohort(:houses => { :id => [house1]}).length
    assert_equal 3, Style.joins(:houses).big_cohort(:houses => { :id => [house1]}, :name => 'foooooooo').length
    # these return 2, which is too small
    assert_equal 0, Style.joins(:houses).big_cohort(:houses => { :id => [house3]}).length
    assert_equal 0, Style.joins(:houses).big_cohort(:houses => { :id => [house3]}, :name => 'classical revival').length
  end
  
  # should this even work in theory?
  def test_002b_simplified_joins
    flunk
    assert_equal 3, Style.big_cohort(:houses => [house1]).length
  end

  def test_003_redefine_any_query_method
    cohort = Citizen.big_cohort(:birthdate => @date_range)
    assert cohort.all? { |c| true }
    assert cohort.any? { |c| true }
    assert !cohort.none? { |c| true }
  end
  
  def test_004_really_run_blocks
    assert_raises(RuntimeError, 'A') do
      Citizen.big_cohort(:birthdate => @date_range).all? { |c| raise 'A' }
    end
    assert_raises(RuntimeError, 'B') do
      Citizen.big_cohort(:birthdate => @date_range).any? { |c| raise 'B' }
    end
    assert_raises(RuntimeError, 'C') do
      Citizen.big_cohort(:birthdate => @date_range).none? { |c| raise 'C' }
    end
  end
  
  def test_005_short_to_json
    cohort = Citizen.big_cohort :birthdate => @date_range, :favorite_color => 'heliotrope'
    assert_equal({ :members => 9 }.to_json, cohort.to_json)
  end
  
  def test_006_doesnt_mess_with_active_record_json
    non_cohort = Citizen.all
    assert_equal non_cohort.to_a.as_json, non_cohort.as_json
  end
  
  def test_007_doesnt_mess_with_active_record_inspect
    non_cohort = Citizen.all
    assert_equal non_cohort.to_a.inspect, non_cohort.inspect
  end
  
  def test_008_short_inspect
    cohort = Citizen.big_cohort :birthdate => @date_range, :favorite_color => 'heliotrope'
    assert_equal "<Cohort scope with 9 members>", cohort.inspect
  end
  
  def test_009_not_reveal_itself_in_to_hash
    cohort = Citizen.big_cohort :birthdate => @date_range, :favorite_color => 'heliotrope'
    assert_equal '{"c":{"members":9}}', { :c => cohort }.to_hash.to_json
  end
  
  def test_010_work_as_delegator
    cohort = Citizen.big_cohort :birthdate => @date_range, :favorite_color => 'heliotrope'
    assert_kind_of Citizen, cohort.last
    assert_kind_of Citizen, cohort.where(:teeth => 31).first
  end
  
  def test_011_combine_scopes_with_or
    nobody = Citizen.big_cohort({:favorite_color => 'oaisdjaoisjd'}, :minimum_cohort_size => 1)
    assert_equal 0, nobody.count
    people_who_love_heliotrope_are_from_the_fifties = Citizen.big_cohort({:favorite_color => 'heliotrope'}, :minimum_cohort_size => 1)
    assert_equal 1, people_who_love_heliotrope_are_from_the_fifties.count
    assert people_who_love_heliotrope_are_from_the_fifties.none? { |c| @date_range.include? c.birthdate }
    their_children_are_born_in_the_eighties = Citizen.big_cohort({:birthdate => @date_range}, :minimum_cohort_size => 1)
    assert_equal 9, their_children_are_born_in_the_eighties.count
    everybody = (people_who_love_heliotrope_are_from_the_fifties + their_children_are_born_in_the_eighties + nobody)
    assert_kind_of CohortScope::Cohort, everybody
    assert_equal 10, everybody.count
  end
  
  private
  
  def style
    @style ||= Style.find 'classical revival'
  end
  
  def house1
    @house1 ||= House.find 2
  end
  
  def house3
    @house3 ||= House.find 3
  end
end
