require 'helper'

class TestBigCohort < Test::Unit::TestCase
  def setup
    Citizen.minimum_cohort_size = 3
    @date_range = (Date.parse('1980-01-01')..Date.parse('1990-01-01'))
  end

  def test_001_empty
    cohort = Citizen.big_cohort :favorite_color => 'heliotrope'
    assert_equal 0, cohort.count
  end
  
  def test_002_optional_minimum_cohort_size_at_runtime
    cohort = Citizen.big_cohort({:favorite_color => 'heliotrope'}, :minimum_cohort_size => 0)
    assert_equal 1, cohort.count
  end

  def test_003_seek_cohort_of_maximum_size
    cohort = Citizen.big_cohort :birthdate => @date_range, :favorite_color => 'heliotrope'
    assert_equal 9, cohort.count
    assert cohort.any? { |m| m.favorite_color != 'heliotrope' }
    assert cohort.all? { |m| @date_range.include? m.birthdate }
  end
  
  def test_004_unsurprising_treatment_of_arrays
    assert_equal 3, Citizen.big_cohort({:favorite_color => 'blue'}, :minimum_cohort_size => 0).count
    assert_equal 1, Citizen.big_cohort({:favorite_color => 'heliotrope'}, :minimum_cohort_size => 0).count
    assert_equal 4, Citizen.big_cohort({:favorite_color => ['heliotrope', 'blue']}, :minimum_cohort_size => 0).count
  end
end
