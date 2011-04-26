require 'helper'

class TestCohortScope < Test::Unit::TestCase
  def setup
    Citizen.minimum_cohort_size = 3
    @date_range = (Date.parse('1980-01-01')..Date.parse('1990-01-01'))
  end

  should "properly use blocks" do
    cohort = Citizen.big_cohort(:birthdate => @date_range)
    assert cohort.all? { |c| true }
    assert cohort.any? { |c| true }
    assert !cohort.none? { |c| true }
  end

  should "actually run blocks" do
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

  should "only show the count in the json representation" do
    cohort = Citizen.big_cohort :birthdate => @date_range, :favorite_color => 'heliotrope'
    assert_equal({ :members => 9 }.to_json, cohort.to_json)
  end
  
  should "not mess with normal as_json" do
    non_cohort = Citizen.all
    assert_equal non_cohort.to_a.as_json, non_cohort.as_json
  end
  
  should "not mess with normal inspect" do
    non_cohort = Citizen.all
    assert_equal non_cohort.to_a.inspect, non_cohort.inspect
  end
  
  should "inspect to a short string" do
    cohort = Citizen.big_cohort :birthdate => @date_range, :favorite_color => 'heliotrope'
    assert_equal "<Massive ActiveRecord scope with 9 members>", cohort.inspect
  end
  
  should "not get fooled into revealing all of its members by a parent's #to_hash" do
    cohort = Citizen.big_cohort :birthdate => @date_range, :favorite_color => 'heliotrope'
    assert_equal '{"c":{"members":9}}', { :c => cohort }.to_hash.to_json
  end

  should "retain the scope's original behavior" do
    cohort = Citizen.big_cohort :birthdate => @date_range, :favorite_color => 'heliotrope'
    assert_kind_of Citizen, cohort.last
    assert_kind_of Citizen, cohort.where(:teeth => 31).first
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
    
    should "take minimum_cohort_size as an optional argument" do
      cohort = Citizen.big_cohort({:favorite_color => 'heliotrope'}, 0)
      assert_equal 1, cohort.count
    end
  
    should "seek a cohort of maximum size" do
      cohort = Citizen.big_cohort :birthdate => @date_range, :favorite_color => 'heliotrope'
      assert_equal 9, cohort.count
      assert cohort.any? { |m| m.favorite_color != 'heliotrope' }
      assert cohort.all? { |m| @date_range.include? m.birthdate }
    end
    
    should "treat arrays in conditions just like ActiveRecord would (i.e., using OR)" do
      assert_equal 3, Citizen.big_cohort({:favorite_color => 'blue'}, 0).count
      assert_equal 1, Citizen.big_cohort({:favorite_color => 'heliotrope'}, 0).count
      assert_equal 4, Citizen.big_cohort({:favorite_color => ['heliotrope', 'blue']}, 0).count
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
    
    should "take minimum_cohort_size as an optional argument" do
      ordered_attributes = ActiveSupport::OrderedHash.new
      ordered_attributes[:favorite_color] = 'heliotrope'
    
      cohort = Citizen.strict_cohort ordered_attributes, 0
      assert_equal 1, cohort.count
    end
  
    should "return an empty cohort if it can't find one that meets size requirements" do
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
