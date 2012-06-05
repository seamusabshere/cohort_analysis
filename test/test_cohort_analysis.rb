require 'helper'

class Flight < ActiveRecord::Base
  col :origin
  col :dest
  col :year, :type => :integer
  col :airline
  col :origin_city
  col :dest_city
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
  def moot_condition
    Arel.sql('9 = 9')
  end

  describe :cohort do
    it "finds the biggest set of records matching the characteristics" do
      FactoryGirl.create(:lax_ord)
      FactoryGirl.create(:lax_sfo)
      assert_count 2, model.cohort(:origin => 'LAX')
      assert_count 1, model.cohort(:dest => 'SFO')
      assert_count 1, model.cohort(:origin => 'LAX', :dest => 'SFO')
      assert_count 0, model.cohort(:dest => 'MSN')
    end

    it "handles arrays of values" do
      FactoryGirl.create(:lax_ord)
      FactoryGirl.create(:lax_sfo)
      assert_count 2, model.cohort(:dest => ['ORD','SFO'])
      assert_count 2, model.cohort(:origin => ['LAX'])
      assert_count 1, model.cohort(:dest => ['SFO'])
      assert_count 1, model.cohort(:origin => ['LAX'], :dest => ['SFO'])
      assert_count 0, model.cohort(:dest => ['MSN'])
      assert_count 1, model.cohort(:dest => ['MSN','SFO'])
    end

    it "matches everything if empty characteristics" do
      FactoryGirl.create(:lax_ord)
      FactoryGirl.create(:lax_sfo)
      assert_count 2, model.cohort({})
    end

    it "discards characteristics to maximize size until the minimum size is met" do
      a = FactoryGirl.create(:lax_ord)
      b = FactoryGirl.create(:lax_sfo)
      cohort = model.cohort({:origin => 'LAX', :dest => 'SFO'}, :minimum_size => 2)
      assert_count 2, cohort
      assert_members [a,b], cohort
    end

    it "returns an empty cohort (basically an impossible condition) unless the minimum size is set" do
      FactoryGirl.create(:lax_ord)
      cohort = model.cohort({:origin => 'LAX'}, :minimum_size => 2)
      assert_count 0, cohort
    end

    it "discards characteristics in order until a minimum size is met" do
      a = FactoryGirl.create(:lax_ord)
      b = FactoryGirl.create(:lax_sfo)
      cohort = model.cohort({:origin => 'LAX', :dest => 'MSN'}, :minimum_size => 2, :priority => [:origin, :dest])
      assert_count 2, cohort
      assert_members [a,b], cohort
    end

    it "returns an empty cohort if discarding characteristics in order has that effect" do
      FactoryGirl.create(:lax_ord)
      FactoryGirl.create(:lax_sfo)
      cohort = model.cohort({:origin => 'LAX', :dest => 'MSN'}, :minimum_size => 2, :priority => [:dest, :origin])
      assert_count 0, cohort
    end

    it "obeys conditions already added" do
      FactoryGirl.create(:lax_ord, :year => 1900)
      FactoryGirl.create(:lax_sfo, :year => 1900)
      FactoryGirl.create(:lax_sfo, :year => 2009)
      FactoryGirl.create(:ord_sfo, :year => 2009)
      year_is_2009 = f_t[:year].eq(2009)

      assert_count 1, model.where(year_is_2009).cohort(:origin => 'LAX').where(moot_condition)
      assert_count 1, model.where(year_is_2009).cohort(:origin => 'LAX', :dest => 'MSN').where(moot_condition)

      assert_count 1, model.where(year_is_2009).cohort({:origin => 'LAX', :dest => 'MSN'}, :priority => [:origin, :dest]).where(moot_condition)
      assert_count 0, model.where(year_is_2009).cohort({:origin => 'LAX', :dest => 'MSN'}, :priority => [:dest, :origin]).where(moot_condition)

      assert_count 0, model.where(year_is_2009).cohort({:origin => 'LAX'}, :minimum_size => 2).where(moot_condition)
      assert_count 0, model.where(year_is_2009).cohort({:origin => 'LAX', :dest => 'MSN'}, :minimum_size => 2).where(moot_condition)
      

      assert_count 1, model.where(year_is_2009).cohort(:origin => 'LAX').where(moot_condition)
      assert_count 1, model.where(year_is_2009).cohort(:origin => 'LAX', :dest => 'SFO').where(moot_condition)

      assert_count 1, model.where(year_is_2009).cohort({:origin => 'LAX', :dest => 'SFO'}, :priority => [:origin, :dest]).where(moot_condition)
      assert_count 1, model.where(year_is_2009).cohort({:origin => 'LAX', :dest => 'SFO'}, :priority => [:dest, :origin]).where(moot_condition)

      assert_count 0, model.where(year_is_2009).cohort({:origin => 'LAX'}, :minimum_size => 2).where(moot_condition)
      assert_count 2, model.where(year_is_2009).cohort({:origin => 'LAX', :dest => 'SFO'}, :minimum_size => 2).where(moot_condition)


      assert_count 1, model.where(year_is_2009).cohort(:origin => 'LAX').where(moot_condition)
      assert_count 1, model.where(year_is_2009).cohort(:origin => 'LAX', :dest => 'ORD').where(moot_condition)

      assert_count 1, model.where(year_is_2009).cohort({:origin => 'LAX', :dest => 'ORD'}, :priority => [:origin, :dest]).where(moot_condition)
      assert_count 0, model.where(year_is_2009).cohort({:origin => 'LAX', :dest => 'ORD'}, :priority => [:dest, :origin]).where(moot_condition)

      assert_count 0, model.where(year_is_2009).cohort({:origin => 'LAX'}, :minimum_size => 2).where(moot_condition)
      assert_count 0, model.where(year_is_2009).cohort({:origin => 'LAX', :dest => 'ORD'}, :minimum_size => 2).where(moot_condition)


      assert_count 1, model.where(year_is_2009).cohort(:origin => 'ORD').where(moot_condition)
      assert_count 1, model.where(year_is_2009).cohort(:origin => 'ORD', :dest => 'MSN').where(moot_condition)

      assert_count 1, model.where(year_is_2009).cohort({:origin => 'ORD', :dest => 'MSN'}, :priority => [:origin, :dest]).where(moot_condition)
      assert_count 0, model.where(year_is_2009).cohort({:origin => 'ORD', :dest => 'MSN'}, :priority => [:dest, :origin]).where(moot_condition)

      assert_count 0, model.where(year_is_2009).cohort({:origin => 'ORD'}, :minimum_size => 2).where(moot_condition)
      assert_count 0, model.where(year_is_2009).cohort({:origin => 'ORD', :dest => 'MSN'}, :minimum_size => 2).where(moot_condition)
    end

    it "carries over into conditions added later" do
      FactoryGirl.create(:lax_ord, :year => 1900)
      FactoryGirl.create(:lax_sfo, :year => 1900)
      FactoryGirl.create(:lax_sfo, :year => 2009)
      FactoryGirl.create(:ord_sfo, :year => 2009)
      year_is_2009 = f_t[:year].eq(2009)

      assert_count 1, model.where(moot_condition).cohort(:origin => 'LAX').where(year_is_2009)
      assert_count 1, model.where(moot_condition).cohort(:origin => 'LAX', :dest => 'MSN').where(year_is_2009)

      assert_count 1, model.where(moot_condition).cohort({:origin => 'LAX', :dest => 'MSN'}, :priority => [:origin, :dest]).where(year_is_2009)
      assert_count 0, model.where(moot_condition).cohort({:origin => 'LAX', :dest => 'MSN'}, :priority => [:dest, :origin]).where(year_is_2009)

      assert_count 0, model.where(moot_condition).cohort({:origin => 'LAX'}, :minimum_size => 2).where(year_is_2009)
      assert_count 0, model.where(moot_condition).cohort({:origin => 'LAX', :dest => 'MSN'}, :minimum_size => 2).where(year_is_2009)
      

      assert_count 1, model.where(moot_condition).cohort(:origin => 'LAX').where(year_is_2009)
      assert_count 1, model.where(moot_condition).cohort(:origin => 'LAX', :dest => 'SFO').where(year_is_2009)

      assert_count 1, model.where(moot_condition).cohort({:origin => 'LAX', :dest => 'SFO'}, :priority => [:origin, :dest]).where(year_is_2009)
      assert_count 1, model.where(moot_condition).cohort({:origin => 'LAX', :dest => 'SFO'}, :priority => [:dest, :origin]).where(year_is_2009)

      assert_count 0, model.where(moot_condition).cohort({:origin => 'LAX'}, :minimum_size => 2).where(year_is_2009)
      assert_count 2, model.where(moot_condition).cohort({:origin => 'LAX', :dest => 'SFO'}, :minimum_size => 2).where(year_is_2009)


      assert_count 1, model.where(moot_condition).cohort(:origin => 'LAX').where(year_is_2009)
      assert_count 1, model.where(moot_condition).cohort(:origin => 'LAX', :dest => 'ORD').where(year_is_2009)

      assert_count 1, model.where(moot_condition).cohort({:origin => 'LAX', :dest => 'ORD'}, :priority => [:origin, :dest]).where(year_is_2009)
      assert_count 0, model.where(moot_condition).cohort({:origin => 'LAX', :dest => 'ORD'}, :priority => [:dest, :origin]).where(year_is_2009)

      assert_count 0, model.where(moot_condition).cohort({:origin => 'LAX'}, :minimum_size => 2).where(year_is_2009)
      assert_count 0, model.where(moot_condition).cohort({:origin => 'LAX', :dest => 'ORD'}, :minimum_size => 2).where(year_is_2009)


      assert_count 1, model.where(moot_condition).cohort(:origin => 'ORD').where(year_is_2009)
      assert_count 1, model.where(moot_condition).cohort(:origin => 'ORD', :dest => 'MSN').where(year_is_2009)

      assert_count 1, model.where(moot_condition).cohort({:origin => 'ORD', :dest => 'MSN'}, :priority => [:origin, :dest]).where(year_is_2009)
      assert_count 0, model.where(moot_condition).cohort({:origin => 'ORD', :dest => 'MSN'}, :priority => [:dest, :origin]).where(year_is_2009)

      assert_count 0, model.where(moot_condition).cohort({:origin => 'ORD'}, :minimum_size => 2).where(year_is_2009)
      assert_count 0, model.where(moot_condition).cohort({:origin => 'ORD', :dest => 'MSN'}, :minimum_size => 2).where(year_is_2009)
    end

    it "can get where sql" do
      FactoryGirl.create(:lax_ord)
      FactoryGirl.create(:lax_sfo)
      model.cohort(:origin => 'LAX').where_sql.delete('"`').must_equal %{WHERE (flights.origin = 'LAX')}
    end

    it "will resolve independently from other cohorts" do
      FactoryGirl.create(:lax_ord)
      FactoryGirl.create(:lax_sfo)
      assert_count 0, model.cohort(:dest => 'SFO').cohort(:dest => 'ORD')
    end

    it "will resolve independently from other cohorts (complex example)" do
      FactoryGirl.create(:lax_ord)
      FactoryGirl.create(:lax_ord, :origin_city => 'Los Angeles', :airline => 'Delta')
      FactoryGirl.create(:lax_sfo)
      FactoryGirl.create(:lax_ord, :origin_city => 'Los Angeles', :airline => 'Delta', :year => 2000)
      FactoryGirl.create(:lax_sfo, :year => 2000)
      year_condition = f_t[:year].eq(2000)

      # sanity check
      assert_count 2, model.where(year_condition)
      assert_count 2, model.cohort(:origin => 'LAX', :dest => 'SFO')
      assert_count 2, model.cohort(:origin_city => 'Los Angeles', :airline => 'Delta')
      
      assert_count 1, model.cohort(:origin => 'LAX', :dest => 'SFO').where(year_condition)
      assert_count 1, model.where(year_condition).cohort(:origin => 'LAX', :dest => 'SFO')
      
      assert_count 2, model.cohort({:origin => 'LAX', :dest => 'SFO'}, :minimum_size => 2).where(year_condition)
      assert_count 2, model.where(year_condition).cohort({:origin => 'LAX', :dest => 'SFO'}, :minimum_size => 2)

      assert_count 1, model.cohort(:origin_city => 'Los Angeles', :airline => 'Delta').where(year_condition)
      assert_count 1, model.where(year_condition).cohort(:origin_city => 'Los Angeles', :airline => 'Delta')
      
      assert_count 1, model.cohort(:origin_city => 'Los Angeles', :airline => 'Delta').where(year_condition)
      assert_count 1, model.where(year_condition).cohort(:origin_city => 'Los Angeles', :airline => 'Delta')
      #--

      assert_count 0, model.cohort(:origin => 'LAX', :dest => 'SFO').cohort(:origin_city => 'Los Angeles', :airline => 'Delta')
      assert_count 0, model.cohort(:origin_city => 'Los Angeles', :airline => 'Delta').cohort(:origin => 'LAX', :dest => 'SFO')
    end

    describe "when used with UNION" do
      before do
        @ord = FactoryGirl.create(:lax_ord)
        @sfo = FactoryGirl.create(:lax_sfo)
      end

      # sanity check!
      it "has tests that use unions properly" do
        ord = model.where(f_t[:dest].eq('ORD'))
        sfo = model.where(f_t[:dest].eq('SFO'))
        ord.projections = [Arel.star]
        sfo.projections = [Arel.star]
        Flight.find_by_sql("SELECT * FROM #{Arel::Nodes::TableAlias.new(ord.union(sfo), 't1').to_sql}").must_equal [@ord, @sfo]
      end
        
      it "builds successful cohorts" do
        ord = model.cohort(:dest => 'ORD').project(Arel.star)
        sfo = model.cohort(:dest => 'SFO').project(Arel.star)
        Flight.find_by_sql("SELECT * FROM #{Arel::Nodes::TableAlias.new(ord.union(sfo), 't1').to_sql}").must_equal [@ord, @sfo]

        msn = model.cohort(:origin => 'LAX', :dest => 'MSN').project(Arel.star)
        lhr = model.cohort(:origin => 'LAX', :dest => 'LHR').project(Arel.star)
        Flight.find_by_sql("SELECT * FROM #{Arel::Nodes::TableAlias.new(msn.union(lhr), 't1').to_sql}").must_equal [@ord, @sfo]
      end

      it "doesn't somehow create unions with false positives" do
        msn = model.cohort(:dest => 'MSN').project(Arel.star)
        lhr = model.cohort(:dest => 'LHR').project(Arel.star)
        count = ActiveRecord::Base.connection.select_value("SELECT COUNT(*) FROM #{Arel::Nodes::TableAlias.new(msn.union(lhr), 't1').to_sql}")
        flunk "count was nil" if count.nil?
        count.to_i.must_equal 0
      end

      it "builds unions where only one side has rows" do
        msn = model.cohort(:dest => 'MSN').project(Arel.star)
        ord = model.cohort(:dest => 'ORD').project(Arel.star)
        Flight.find_by_sql("SELECT * FROM #{Arel::Nodes::TableAlias.new(msn.union(ord), 't1').to_sql}").must_equal [@ord]
      end
    end
  end
end

describe CohortAnalysis do
  def assert_count(expected_count, relation)
    relation = relation.clone
    relation.projections = [Arel.sql('COUNT(*)')]
    sql = relation.to_sql
    count = ActiveRecord::Base.connection.select_value(sql)
    flunk "count was nil" if count.nil?
    count.to_i.must_equal expected_count
  end

  def assert_members(expected_members, relation)
    relation = relation.clone
    table = relation.source.left
    relation.projections = [Arel.star]
    actual_members = Flight.find_by_sql relation.to_sql
    actual_members.map(&:id).sort.must_equal expected_members.map(&:id).sort
  end

  def f_t
    Arel::Table.new(:flights)
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
