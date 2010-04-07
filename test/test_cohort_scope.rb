require 'helper'

class TestCohortScope < Test::Unit::TestCase
  def setup
    Citizen.minimum_cohort_size = 3
    @date_range = (Date.parse('1980-01-01')..Date.parse('1990-01-01'))
  end

  should "raise if no minimum_cohort_size is specified" do
    Citizen.minimum_cohort_size = nil
    assert_raises(RuntimeError) {
      Citizen.big_cohort Hash.new
    }
    assert_raises(RuntimeError) {
      Citizen.strict_cohort ActiveSupport::OrderedHash.new
    }
  end

  context "big_cohort" do
    should "return an empty cohort if it can't find one that meets size requirements" do
      cohort = Citizen.big_cohort :favorite_color => 'heliotrope'
      assert_equal 0, cohort.count
    end
  
    should "seek a cohort of maximum size" do
      cohort = Citizen.big_cohort :birthdate => @date_range, :favorite_color => 'heliotrope'
      assert_equal 9, cohort.count
      assert cohort.any? { |m| m.favorite_color != 'heliotrope' }
      assert cohort.all? { |m| @date_range.include? m.birthdate }
    end
    
    should "raise if an OrderedHash is given to big_cohort" do
      assert_raises(ArgumentError) {
        Citizen.big_cohort ActiveSupport::OrderedHash.new
      }
    end
  end
  
  context "strict_cohort" do
    should "raise if a non-OrderedHash is given to strict_cohort" do
      assert_raises(ArgumentError) {
        Citizen.strict_cohort Hash.new
      }
    end
  
    should "return an empty (strict) cohort if it can't find one that meets size requirements" do
      ordered_attributes = ActiveSupport::OrderedHash.new
      ordered_attributes[:favorite_color] = 'heliotrope'
    
      cohort = Citizen.strict_cohort ordered_attributes
      assert_equal 0, cohort.count
    end
  
    should "seek a cohort by discarding attributes in order" do
      favorite_color_matters_most = ActiveSupport::OrderedHash.new
      favorite_color_matters_most[:favorite_color] = 'heliotrope'
      favorite_color_matters_most[:birthdate] = @date_range
    
      birthdate_matters_most = ActiveSupport::OrderedHash.new
      birthdate_matters_most[:birthdate] = @date_range
      birthdate_matters_most[:favorite_color] = 'heliotrope'
    
      cohort = Citizen.strict_cohort favorite_color_matters_most
      assert_equal 0, cohort.count
    
      cohort = Citizen.strict_cohort birthdate_matters_most
      assert_equal 9, cohort.count
    end
  end
end
