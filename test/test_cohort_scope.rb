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
  
  def test_002_to_sql
    assert %r{BETWEEN.*#{@date_range.first}.*#{@date_range.last}}.match(Citizen.big_cohort(:birthdate => @date_range).to_sql)
    assert %r{.citizens...favorite_color. = 'heliotrope'}.match(Citizen.big_cohort({:favorite_color => 'heliotrope'}, :minimum_cohort_size => 1).to_sql)
    assert_equal %{1 = 2}, Citizen.big_cohort(:favorite_color => 'osijdfosidfj').to_sql
  end
  
  def test_011_combine_scopes_with_or
    nobody = Citizen.big_cohort({:favorite_color => 'oaisdjaoisjd'}, :minimum_cohort_size => 1)
    assert_equal 0, Citizen.where(nobody).count
    people_who_love_heliotrope_are_from_the_fifties = Citizen.big_cohort({:favorite_color => 'heliotrope'}, :minimum_cohort_size => 1)
    assert_equal 1, Citizen.where(people_who_love_heliotrope_are_from_the_fifties).count
    assert Citizen.where(people_who_love_heliotrope_are_from_the_fifties).none? { |c| @date_range.include? c.birthdate }
    their_children_are_born_in_the_eighties = Citizen.big_cohort({:birthdate => @date_range}, :minimum_cohort_size => 1)
    assert_equal 9, Citizen.where(their_children_are_born_in_the_eighties).count
    everybody = people_who_love_heliotrope_are_from_the_fifties.or(their_children_are_born_in_the_eighties).or(nobody)
    assert_equal 10, Citizen.where(everybody).count
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
