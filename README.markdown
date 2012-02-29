# cohort_analysis

Lets you do cohort analysis based on two strategies: "big", which discards characteristics for the maximum cohort result, and "strict", which discards characteristics in order until a minimum cohort size is reached.

Replaces [`cohort_scope`](https://github.com/seamusabshere/cohort_scope).

## Where it's used

* [Brighter Planet CM1 Impact Estimate web service](http://impact.brighterplanet.com) 
* [Flight environmental impact model](https://github.com/brighterplanet/flight)

## Strategies

<dl>
  <dt><code>:big</code></dt>
  <dd>Default. Iteratively discards the characteristic that is most "restrictive," yielding the largest possible cohort. Note that it stops discarding after the minimum cohort size is reached.</dd>
  <dt><code>:strict</code></dt>
  <dd>Discards characteristics according to <code>:priority</code>.</dd>
</dl>

### `:big` example

This is straight from the tests:

    # make some fixtures
    1_000.times { FactoryGirl.create(:lax) }
    100.times { FactoryGirl.create(:lax_sfo) }
    10.times { FactoryGirl.create(:lax_sfo_co) }
    3.times { FactoryGirl.create(:lax_sfo_a320) }
    1.times { FactoryGirl.create(:lax_sfo_aa_a320) }

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

### `:strict` example

Also from the tests...

    # make some fixtures
    1_000.times { FactoryGirl.create(:lax) }
    100.times { FactoryGirl.create(:lax_sfo) }
    10.times { FactoryGirl.create(:lax_sfo_co) }
    3.times { FactoryGirl.create(:lax_sfo_a320) }
    1.times { FactoryGirl.create(:lax_sfo_aa_a320) }

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

## Copyright

Copyright (c) 2012 Brighter Planet, Inc.
