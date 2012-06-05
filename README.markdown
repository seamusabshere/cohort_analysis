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

## Copyright

Copyright (c) 2012 Brighter Planet, Inc.
