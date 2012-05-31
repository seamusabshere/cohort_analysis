require 'helper'

class Flight < ActiveRecord::Base
  col :origin
  col :dest
  col :year, :type => :integer
end
Flight.auto_upgrade!

FactoryGirl.define do
  factory :lax_sfo, :class => Flight do
    origin 'LAX'
    dest 'SFO'
  end
  factory :lax_ord, :class => Flight do
    origin 'LAX'
    dest 'ORD'
  end
  factory :ord_sfo, :class => Flight do
    origin 'ORD'
    dest 'SFO'
  end
end

shared_examples_for 'an adapter the provides #cohort' do
  describe :cohort do
    it "finds the biggest set of records matching the characteristics" do
      FactoryGirl.create(:lax_ord)
      FactoryGirl.create(:lax_sfo)
      assert_count 2, model.cohort(:origin => 'LAX')
      assert_count 1, model.cohort(:dest => 'SFO')
      assert_count 1, model.cohort(:origin => 'LAX', :dest => 'SFO')
      assert_count 0, model.cohort(:dest => 'MSN')
    end

    it "matches everything if empty characteristics" do
      FactoryGirl.create(:lax_ord)
      FactoryGirl.create(:lax_sfo)
      assert_count 2, model.cohort({})
    end

    it "discards characteristics to maximize size until the minimum size is met" do
      FactoryGirl.create(:lax_ord)
      FactoryGirl.create(:lax_sfo)
      cohort = model.cohort({:origin => 'LAX', :dest => 'SFO'}, :minimum_size => 2)
      assert_count 2, cohort
      assert_constraint({:origin => 'LAX'}, cohort)
    end

    it "returns an empty cohort (basically an impossible condition) unless the minimum size is set" do
      FactoryGirl.create(:lax_ord)
      cohort = model.cohort({:origin => 'LAX'}, :minimum_size => 2)
      assert_count 0, cohort
      assert_constraint '1 = 2', cohort
    end

    it "discards characteristics in order until a minimum size is met" do
      FactoryGirl.create(:lax_ord)
      FactoryGirl.create(:lax_sfo)
      cohort = model.cohort({:origin => 'LAX', :dest => 'MSN'}, :minimum_size => 2, :priority => [:origin, :dest])
      assert_count 2, cohort
      assert_constraint({:origin => 'LAX'}, cohort)
    end

    it "returns an empty cohort if discarding characteristics in order has that effect" do
      FactoryGirl.create(:lax_ord)
      FactoryGirl.create(:lax_sfo)
      cohort = model.cohort({:origin => 'LAX', :dest => 'MSN'}, :minimum_size => 2, :priority => [:dest, :origin])
      assert_count 0, cohort
      assert_constraint('1 = 2', cohort)
    end

    it "obeys conditions already added" do
      FactoryGirl.create(:lax_ord, :year => 1900)
      FactoryGirl.create(:lax_sfo, :year => 1900)
      FactoryGirl.create(:lax_sfo, :year => 2009)
      FactoryGirl.create(:ord_sfo, :year => 2009)
      f_t = Arel::Table.new(:flights)
      year_is_2009 = f_t[:year].eq(2009)

      assert_count 1, model.where(year_is_2009).cohort(:origin => 'LAX').where('9 = 9')
      assert_count 1, model.where(year_is_2009).cohort(:origin => 'LAX', :dest => 'MSN').where('9 = 9')

      assert_count 1, model.where(year_is_2009).cohort({:origin => 'LAX', :dest => 'MSN'}, :priority => [:origin, :dest]).where('9 = 9')
      assert_count 0, model.where(year_is_2009).cohort({:origin => 'LAX', :dest => 'MSN'}, :priority => [:dest, :origin]).where('9 = 9')

      assert_count 0, model.where(year_is_2009).cohort({:origin => 'LAX'}, :minimum_size => 2).where('9 = 9')
      assert_count 0, model.where(year_is_2009).cohort({:origin => 'LAX', :dest => 'MSN'}, :minimum_size => 2).where('9 = 9')
      

      assert_count 1, model.where(year_is_2009).cohort(:origin => 'LAX').where('9 = 9')
      assert_count 1, model.where(year_is_2009).cohort(:origin => 'LAX', :dest => 'SFO').where('9 = 9')

      assert_count 1, model.where(year_is_2009).cohort({:origin => 'LAX', :dest => 'SFO'}, :priority => [:origin, :dest]).where('9 = 9')
      assert_count 1, model.where(year_is_2009).cohort({:origin => 'LAX', :dest => 'SFO'}, :priority => [:dest, :origin]).where('9 = 9')

      assert_count 0, model.where(year_is_2009).cohort({:origin => 'LAX'}, :minimum_size => 2).where('9 = 9')
      assert_count 2, model.where(year_is_2009).cohort({:origin => 'LAX', :dest => 'SFO'}, :minimum_size => 2).where('9 = 9')


      assert_count 1, model.where(year_is_2009).cohort(:origin => 'LAX').where('9 = 9')
      assert_count 1, model.where(year_is_2009).cohort(:origin => 'LAX', :dest => 'ORD').where('9 = 9')

      assert_count 1, model.where(year_is_2009).cohort({:origin => 'LAX', :dest => 'ORD'}, :priority => [:origin, :dest]).where('9 = 9')
      assert_count 0, model.where(year_is_2009).cohort({:origin => 'LAX', :dest => 'ORD'}, :priority => [:dest, :origin]).where('9 = 9')

      assert_count 0, model.where(year_is_2009).cohort({:origin => 'LAX'}, :minimum_size => 2).where('9 = 9')
      assert_count 0, model.where(year_is_2009).cohort({:origin => 'LAX', :dest => 'ORD'}, :minimum_size => 2).where('9 = 9')


      assert_count 1, model.where(year_is_2009).cohort(:origin => 'ORD').where('9 = 9')
      assert_count 1, model.where(year_is_2009).cohort(:origin => 'ORD', :dest => 'MSN').where('9 = 9')

      assert_count 1, model.where(year_is_2009).cohort({:origin => 'ORD', :dest => 'MSN'}, :priority => [:origin, :dest]).where('9 = 9')
      assert_count 0, model.where(year_is_2009).cohort({:origin => 'ORD', :dest => 'MSN'}, :priority => [:dest, :origin]).where('9 = 9')

      assert_count 0, model.where(year_is_2009).cohort({:origin => 'ORD'}, :minimum_size => 2).where('9 = 9')
      assert_count 0, model.where(year_is_2009).cohort({:origin => 'ORD', :dest => 'MSN'}, :minimum_size => 2).where('9 = 9')
    end

    it "carries over into conditions added later" do
      FactoryGirl.create(:lax_ord, :year => 1900)
      FactoryGirl.create(:lax_sfo, :year => 1900)
      FactoryGirl.create(:lax_sfo, :year => 2009)
      FactoryGirl.create(:ord_sfo, :year => 2009)
      f_t = Arel::Table.new(:flights)
      year_is_2009 = f_t[:year].eq(2009)

      assert_count 1, model.where('9 = 9').cohort(:origin => 'LAX').where(year_is_2009)
      assert_count 1, model.where('9 = 9').cohort(:origin => 'LAX', :dest => 'MSN').where(year_is_2009)

      assert_count 1, model.where('9 = 9').cohort({:origin => 'LAX', :dest => 'MSN'}, :priority => [:origin, :dest]).where(year_is_2009)
      assert_count 0, model.where('9 = 9').cohort({:origin => 'LAX', :dest => 'MSN'}, :priority => [:dest, :origin]).where(year_is_2009)

      assert_count 0, model.where('9 = 9').cohort({:origin => 'LAX'}, :minimum_size => 2).where(year_is_2009)
      assert_count 0, model.where('9 = 9').cohort({:origin => 'LAX', :dest => 'MSN'}, :minimum_size => 2).where(year_is_2009)
      

      assert_count 1, model.where('9 = 9').cohort(:origin => 'LAX').where(year_is_2009)
      assert_count 1, model.where('9 = 9').cohort(:origin => 'LAX', :dest => 'SFO').where(year_is_2009)

      assert_count 1, model.where('9 = 9').cohort({:origin => 'LAX', :dest => 'SFO'}, :priority => [:origin, :dest]).where(year_is_2009)
      assert_count 1, model.where('9 = 9').cohort({:origin => 'LAX', :dest => 'SFO'}, :priority => [:dest, :origin]).where(year_is_2009)

      assert_count 0, model.where('9 = 9').cohort({:origin => 'LAX'}, :minimum_size => 2).where(year_is_2009)
      assert_count 2, model.where('9 = 9').cohort({:origin => 'LAX', :dest => 'SFO'}, :minimum_size => 2).where(year_is_2009)


      assert_count 1, model.where('9 = 9').cohort(:origin => 'LAX').where(year_is_2009)
      assert_count 1, model.where('9 = 9').cohort(:origin => 'LAX', :dest => 'ORD').where(year_is_2009)

      assert_count 1, model.where('9 = 9').cohort({:origin => 'LAX', :dest => 'ORD'}, :priority => [:origin, :dest]).where(year_is_2009)
      assert_count 0, model.where('9 = 9').cohort({:origin => 'LAX', :dest => 'ORD'}, :priority => [:dest, :origin]).where(year_is_2009)

      assert_count 0, model.where('9 = 9').cohort({:origin => 'LAX'}, :minimum_size => 2).where(year_is_2009)
      assert_count 0, model.where('9 = 9').cohort({:origin => 'LAX', :dest => 'ORD'}, :minimum_size => 2).where(year_is_2009)


      assert_count 1, model.where('9 = 9').cohort(:origin => 'ORD').where(year_is_2009)
      assert_count 1, model.where('9 = 9').cohort(:origin => 'ORD', :dest => 'MSN').where(year_is_2009)

      assert_count 1, model.where('9 = 9').cohort({:origin => 'ORD', :dest => 'MSN'}, :priority => [:origin, :dest]).where(year_is_2009)
      assert_count 0, model.where('9 = 9').cohort({:origin => 'ORD', :dest => 'MSN'}, :priority => [:dest, :origin]).where(year_is_2009)

      assert_count 0, model.where('9 = 9').cohort({:origin => 'ORD'}, :minimum_size => 2).where(year_is_2009)
      assert_count 0, model.where('9 = 9').cohort({:origin => 'ORD', :dest => 'MSN'}, :minimum_size => 2).where(year_is_2009)
    end
  end
end

describe CohortAnalysis do
  def assert_count(expected_count, cohort)
    sql = cohort.project('COUNT(*)').to_sql
    ActiveRecord::Base.connection.select_value(sql).must_equal expected_count
  end
  def assert_constraint(expected_constraints, cohort)
    table = cohort.source.left
    if expected_constraints.is_a?(Hash)
      expected_constraints = expected_constraints.map { |k, v| table[k].eq(v) }.inject(:and).to_sql
    end
    cohort.constraints.map(&:to_sql).must_equal [expected_constraints]
  end

  describe 'ArelSelectManagerInstanceMethods' do
    it_behaves_like 'an adapter the provides #cohort'
    def model
      Arel::SelectManager.new(ActiveRecord::Base, Arel::Table.new(:flights))
    end
  end

  describe 'ArelTableInstanceMethods' do
    it_behaves_like 'an adapter the provides #cohort'
    def model
      Arel::Table.new(:flights, ActiveRecord::Base)
    end
  end

  describe 'ActiveRecordBaseClassMethods' do
    it_behaves_like 'an adapter the provides #cohort'
    def model
      Flight
    end
  end

  describe 'ActiveRecordRelationInstanceMethods' do
    it_behaves_like 'an adapter the provides #cohort'
    def model
      Flight.scoped
    end
  end
end
