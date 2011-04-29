require 'helper'

class TestStrictCohort < Test::Unit::TestCase
  def setup
    Citizen.minimum_cohort_size = 3
    @date_range = (Date.parse('1980-01-01')..Date.parse('1990-01-01'))
  end

  def test_001_empty
    cohort = Citizen.strict_cohort 
    assert_equal 0, cohort.count
  end
  
  def test_002_optional_minimum_cohort_size_at_runtime
    cohort = Citizen.strict_cohort [:favorite_color, 'heliotrope'], :minimum_cohort_size => 0
    assert_equal 1, cohort.count
  end

  def test_003_seek_cohort_by_discarding_constraints_in_order
    favorite_color_matters_most = [ [:favorite_color, 'heliotrope'], [:birthdate, @date_range] ]
    birthdate_matters_most =      [ [:birthdate, @date_range], [:favorite_color, 'heliotrope'] ]

    cohort = Citizen.strict_cohort *favorite_color_matters_most
    assert_equal 0, cohort.count

    cohort = Citizen.strict_cohort *birthdate_matters_most
    assert_equal 9, cohort.count
  end
end
