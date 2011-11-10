# gaga experiments
This is an experiment to test the new direction for Noah

The idea is:

- objects are defined by a schema
- data is stored in git

Below is not up to date. For now, please look at the `importer.rb` and `test.rb` files.
`app.rb` has basic read support.

Obviously the JSON is ugly and basic for now. 

One little idea we're kicking around is that cluster consistency is done via merging changes from either an elected master or simply all nodes in the cluster.

Fun stuff!

_old readme below here_

## Schema
_note this section is not up to date with latest changes_
Right now the schema support is VERY basic. It understands strings and arrays for validation.

`bundle install & irb -r./model.rb`

A new object is created by loading a schema.

```ruby
h = Model.load(@json)
# #<Host:0x00000002366a30 @db=#<Gaga:0x000000023669b8 @options={:repo=>".data"}, path"/home/jvincent/development/experiments/ruby/gaga/.data/", schema{"id"=>"host", "attributes"=>{"name"=>"string", "status"=>["up", "down", "pending_up", "pending_down"]}}, version1
h.class
# Host
```

Validations are done using attributes in the schema. This approach is modeled after Ohm's validation strategy.

```ruby
h.valid?
# false
h.errors
# [[:name, :invalid_format], [:status, :invalid_option]]
h.name = "host1.domain.com"
h.valid?
# false
h.errors
# [[:status, :invalid_option]]
h.status = "down"
h.valid?
# true
```

Data is persisted to a git repo via Gaga

```ruby
h.save
# "48b33dfb2da7c7a54007001f1344a52c4dc66ad9"
```

If you restart the irb session:

```ruby
h = Model.load(@json)
h['host1.domain.com'].status
# down
```

Obviously this is VERY raw. The initial plan is that the default backend for Noah will be moved to git via Gaga (or some permutation of Gaga).
I have this stupid crazy idea that in a "cluster" of Noah servers, consistency is reached between servers via a merge operation.
Persistence backends are planned to be pluggable with Redis and Git as the initial ones.
