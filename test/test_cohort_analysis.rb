require 'helper'

c = ActiveRecord::Base.connection
c.create_table 'flights', :force => true do |t|
  t.string 'origin'
  t.string 'dest'
  t.string 'airline'
  t.string 'plane'
end

class Flight < ActiveRecord::Base
end

FactoryGirl.define do
  factory :lax, :class => Flight do
    origin 'LAX'
  end
  factory :lax_sfo, :class => Flight do
    origin 'LAX'
    dest 'SFO'
  end
  factory :lax_sfo_co, :class => Flight do
    origin 'LAX'
    dest 'SFO'
    airline 'Continental'
  end
  factory :lax_sfo_a320, :class => Flight do
    origin 'LAX'
    dest 'SFO'
    plane 'A320'
  end
  factory :lax_sfo_aa_a320, :class => Flight do
    origin 'LAX'
    dest 'SFO'
    airline 'American'
    plane 'A320'
  end
end

describe CohortAnalysis do
  before do
    Flight.delete_all
  end

  describe 'ActiveRecordBaseClassMethods' do
    describe :cohort do
      it "defaults to :minimum_size => 1" do
        FactoryGirl.create(:lax)
        Flight.cohort({:origin => 'LAX'}).count.must_equal 1
        Flight.cohort({:origin => 'LAX'}, :minimum_size => 2).count.must_equal 0
      end

      it "doesn't discard characteristics if it doesn't need to" do
        FactoryGirl.create(:lax)
        FactoryGirl.create(:lax_sfo)
        Flight.cohort(:origin => 'LAX', :dest => 'SFO').count.must_equal 1
      end

      it "discards characteristics until it can fulfil the minimum size" do
        FactoryGirl.create(:lax)
        FactoryGirl.create(:lax_sfo)
        drops_dest = Flight.cohort({:origin => 'LAX', :dest => 'SFO'}, :minimum_size => 2)
        drops_dest.count.must_equal 2
        drops_dest.one? { |flight| flight.dest != 'SFO' }.must_equal true
      end

      it "defaults to :strategy => :big" do
        FactoryGirl.create(:lax)
        Flight.cohort({:origin => 'LAX', :dest => 'SFO'}, :strategy => :big).count.must_equal Flight.cohort(:origin => 'LAX', :dest => 'SFO').count
        Flight.cohort({:dest => 'SFO', :origin => 'LAX'}, :strategy => :big).count.must_equal Flight.cohort(:dest => 'SFO', :origin => 'LAX').count
      end

      it "offers :strategy => :strict" do
        FactoryGirl.create(:lax)
        if RUBY_VERSION >= '1.9'
          # native ordered hashes
          Flight.cohort({:origin => 'LAX', :dest => 'SFO'}, :strategy => :strict).count.must_equal 1
          Flight.cohort({:dest => 'SFO', :origin => 'LAX'}, :strategy => :strict).count.must_equal 0
        else
          # activesupport provides ActiveSupport::OrderedHash
          origin_important = ActiveSupport::OrderedHash.new
          origin_important[:origin] = 'LAX'
          origin_important[:dest] = 'SFO'
          dest_important = ActiveSupport::OrderedHash.new
          dest_important[:dest] = 'SFO'
          dest_important[:origin] = 'LAX'
          Flight.cohort(origin_important, :strategy => :strict).count.must_equal 1
          Flight.cohort(dest_important, :strategy => :strict).count.must_equal 0

          lambda {
            Flight.cohort({:origin => 'LAX', :dest => 'SFO'}, :strategy => :strict).count
          }.must_raise(ArgumentError, 'hash')
        end
      end

      it "lets you pick :priority of keys when using :strict strategy" do
        FactoryGirl.create(:lax)
        Flight.cohort({:origin => 'LAX', :dest => 'SFO'}, :strategy => :strict, :priority => [:origin, :dest]).count.must_equal 1
        Flight.cohort({:origin => 'LAX', :dest => 'SFO'}, :strategy => :strict, :priority => [:dest, :origin]).count.must_equal 0
        Flight.cohort({:dest => 'SFO', :origin => 'LAX'}, :strategy => :strict, :priority => [:origin, :dest]).count.must_equal 1
        Flight.cohort({:dest => 'SFO', :origin => 'LAX'}, :strategy => :strict, :priority => [:dest, :origin]).count.must_equal 0
      end

      it "lets you play with more than 1 or 2 characteristics" do
        ActiveRecord::Base.silence do
          # make some fixtures
          1_000.times { FactoryGirl.create(:lax) }
          100.times { FactoryGirl.create(:lax_sfo) }
          10.times { FactoryGirl.create(:lax_sfo_co) }
          3.times { FactoryGirl.create(:lax_sfo_a320) }
          1.times { FactoryGirl.create(:lax_sfo_aa_a320) }
        end
        Flight.count.must_equal 1_114 # sanity check

        lax_sfo_aa_a320 = {:origin => 'LAX', :dest => 'SFO', :airline => 'American', :plane => 'A320'}
        # don't discard anything
        Flight.cohort(lax_sfo_aa_a320).count.must_equal 1
        # discard airline
        Flight.cohort(lax_sfo_aa_a320, :minimum_size => 2).count.must_equal 4
        # discard plane and airline
        Flight.cohort(lax_sfo_aa_a320, :minimum_size => 5).count.must_equal 114
        # discard plane and airline and dest
        Flight.cohort(lax_sfo_aa_a320, :minimum_size => 115).count.must_equal 1_114

        lax_sfo_a320 = {:origin => 'LAX', :dest => 'SFO', :plane => 'A320'}
        # don't discard anything
        Flight.cohort(lax_sfo_a320).count.must_equal 4
        # discard plane
        Flight.cohort(lax_sfo_a320, :minimum_size => 5).count.must_equal 114
        # discard plane and dest
        Flight.cohort(lax_sfo_a320, :minimum_size => 115).count.must_equal 1_114

        # off the rails here a bit
        woah_lax_co_a320 = {:origin => 'LAX', :airline => 'Continental', :plane => 'A320'}
        # discard plane
        Flight.cohort(woah_lax_co_a320).count.must_equal 10
        # discard plane and airline
        Flight.cohort(woah_lax_co_a320, :minimum_size => 11).count.must_equal 1_114
      end

      it "lets you play with multiple characteristics in :strategy => :strict" do
        ActiveRecord::Base.silence do
          # make some fixtures
          1_000.times { FactoryGirl.create(:lax) }
          100.times { FactoryGirl.create(:lax_sfo) }
          10.times { FactoryGirl.create(:lax_sfo_co) }
          3.times { FactoryGirl.create(:lax_sfo_a320) }
          1.times { FactoryGirl.create(:lax_sfo_aa_a320) }
        end

        lax_sfo_aa_a320 = {:origin => 'LAX', :dest => 'SFO', :airline => 'American', :plane => 'A320'}
        priority = [:origin, :dest, :airline, :plane]
        # discard nothing
        Flight.cohort(lax_sfo_aa_a320, :strategy => :strict, :priority => priority).count.must_equal 1
        # (force) discard plane, then (force) discard airline
        Flight.cohort(lax_sfo_aa_a320, :strategy => :strict, :priority => priority, :minimum_size => 2).count.must_equal 114
        # (force) discard plane, then (force) discard airline, then (force) discard dest
        Flight.cohort(lax_sfo_aa_a320, :strategy => :strict, :priority => priority, :minimum_size => 115).count.must_equal 1_114

        priority = [:plane, :airline, :dest, :origin]
        # discard nothing
        Flight.cohort(lax_sfo_aa_a320, :strategy => :strict, :priority => priority).count.must_equal 1
        # (force) discard origin, then (force) discard dest, then (force) discard airline
        Flight.cohort(lax_sfo_aa_a320, :strategy => :strict, :priority => priority, :minimum_size => 2).count.must_equal 4
        # gives up!
        Flight.cohort(lax_sfo_aa_a320, :strategy => :strict, :priority => priority, :minimum_size => 5).count.must_equal 0
      end
    end

    describe :cohort_constraint do
      it "can be used like other ARel constraints" do
        FactoryGirl.create(:lax)
        Flight.where(Flight.cohort_constraint(:origin => 'LAX')).count.must_equal 1
        Flight.where(Flight.cohort_constraint({:origin => 'LAX'}, :minimum_size => 2)).count.must_equal 0
      end

      it "can be combined with other ARel constraints" do
        FactoryGirl.create(:lax)
        FactoryGirl.create(:lax_sfo)
        origin_lax_constraint = Flight.cohort_constraint(:origin => 'LAX')
        dest_sfo_constraint = Flight.arel_table[:dest].eq('SFO')
        Flight.where(dest_sfo_constraint.and(origin_lax_constraint)).count.must_equal 1
        Flight.where(dest_sfo_constraint.or(origin_lax_constraint)).count.must_equal 2
        Flight.where(origin_lax_constraint.and(dest_sfo_constraint)).count.must_equal 1
        Flight.where(origin_lax_constraint.or(dest_sfo_constraint)).count.must_equal 2
      end

      # Caution!
      it "is NOT smart enough to enforce minimum size when composed" do
        FactoryGirl.create(:lax)
        FactoryGirl.create(:lax_sfo)
        origin_lax_constraint = Flight.cohort_constraint({:origin => 'LAX'}, :minimum_size => 2)
        dest_sfo_constraint = Flight.arel_table[:dest].eq('SFO')
        Flight.where(dest_sfo_constraint.and(origin_lax_constraint)).count.must_equal 1 # see how minimum_size is ignored?
        Flight.where(origin_lax_constraint.and(dest_sfo_constraint)).count.must_equal 1 # it's because the cohort constraint resolves itself before allowing the ARel visitor to continue
      end
    end
  end

  describe 'ActiveRecordRelationInstanceMethods' do
    describe :cohort do
      it "is the proper way to compose when other ARel constraints are present" do
        FactoryGirl.create(:lax)
        FactoryGirl.create(:lax_sfo)
        Flight.where(:dest => 'SFO').cohort(:origin => 'LAX').count.must_equal 1
        Flight.where(:dest => 'SFO').cohort({:origin => 'LAX'}, :minimum_size => 2).count.must_equal 0
      end
    end
    describe :cohort_constraint do
      it "can also be used (carefully) to compose with other ARel constraints" do
        FactoryGirl.create(:lax)
        FactoryGirl.create(:lax_sfo)
        dest_sfo_relation = Flight.where(:dest => 'SFO')
        origin_lax_constraint_from_dest_sfo_relation = dest_sfo_relation.cohort_constraint(:origin => 'LAX')
        Flight.where(origin_lax_constraint_from_dest_sfo_relation).count.must_equal 1
        dest_sfo_relation = Flight.where(:dest => 'SFO')
        origin_lax_constraint_from_dest_sfo_relation = dest_sfo_relation.cohort_constraint({:origin => 'LAX'}, :minimum_size => 2)
        Flight.where(origin_lax_constraint_from_dest_sfo_relation).count.must_equal 0
      end
    end
  end
end
