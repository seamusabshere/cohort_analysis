require 'helper'

class TestCohortScope < Test::Unit::TestCase
  def setup
    Citizen.minimum_cohort_size = 3
    @eighties = (Date.parse('1980-01-01')..Date.parse('1990-01-01'))
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
    assert %r{BETWEEN.*#{@eighties.first}.*#{@eighties.last}}.match(Citizen.big_cohort(:birthdate => @eighties).to_sql)
    assert %r{.citizens...favorite_color. = 'heliotrope'}.match(Citizen.big_cohort({:favorite_color => 'heliotrope'}, :minimum_cohort_size => 1).to_sql)
    assert_equal %{1 = 2}, Citizen.big_cohort(:favorite_color => 'osijdfosidfj').to_sql
  end
  
  def test_003_composability
    cohort = Citizen.big_cohort :birthdate => @eighties
    assert_equal 9, Citizen.where(cohort).count
    assert_equal 0, Citizen.where(cohort.and(Citizen.arel_table[:favorite_color].eq('heliotrope'))).count
    assert_equal 10, Citizen.where(cohort.or(Citizen.arel_table[:favorite_color].eq('heliotrope'))).count
  end

  def test_004_minimum_cohort_size
    less_than_30_teeth = Citizen.arel_table[:teeth].lt(30)
    # correct
    candidates = Citizen.where(less_than_30_teeth)
    assert_equal 8, candidates.count
    assert_equal 6, candidates.where(candidates.big_cohort({:birthdate => @eighties}, :minimum_cohort_size => 6)).count
    assert_equal 0, candidates.where(candidates.big_cohort({:birthdate => @eighties}, :minimum_cohort_size => 7)).count
    # # incorrect
    candidates = Citizen.scoped
    assert_equal 6, candidates.where(candidates.big_cohort({:birthdate => @eighties}, :minimum_cohort_size => 7).and(less_than_30_teeth)).count
    assert_equal 6, candidates.where(less_than_30_teeth.and(candidates.big_cohort({:birthdate => @eighties}, :minimum_cohort_size => 7))).count

  end


  def test_011_combine_scopes_with_or
    nobody = Citizen.big_cohort({:favorite_color => 'oaisdjaoisjd'}, :minimum_cohort_size => 1)
    assert_equal 0, Citizen.where(nobody).count
    people_who_love_heliotrope_are_from_the_fifties = Citizen.big_cohort({:favorite_color => 'heliotrope'}, :minimum_cohort_size => 1)
    assert_equal 1, Citizen.where(people_who_love_heliotrope_are_from_the_fifties).count
    assert Citizen.where(people_who_love_heliotrope_are_from_the_fifties).none? { |c| @eighties.include? c.birthdate }
    their_children_are_born_in_the_eighties = Citizen.big_cohort({:birthdate => @eighties}, :minimum_cohort_size => 1)
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
