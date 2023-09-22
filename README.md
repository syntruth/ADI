# Active Directory Interface (ADI)

Ruby Integration with Microsoft's Active Directory system based on original code
by [James Hunt](https://rubygems.org/gems/activedirectory). The original github
page is no longer accessible.

This is a from-the-side ground-up reworking of the code, in attempts to bring it
up to modern Ruby standards and to make it easier to understand and extend.

## Differences

I tried to keep the `find` calling semantics the same as much as possible, with
the ability to add which attributes that will be returned from Active Directory.
The `User` type has a set of default, hopefully reasonable attributes, to keep
as much functionality of the original library as possible, in regards to finding
managers, direct reports, and checking for account disabling, etc.

That said, ADI implements a new Query language (see below) that is backed by a
Finder class, to abstract that functionality out of the Active Directory Types
classes. The LDAP connection now belongs to the main ADI class, and the Type
classes using the ADI module to call into the AD server.

## Query usage

ADI comes with a built-in query API, to make the `find` calls a bit more
semantic and easier to build programmatically, as the query can be built upon
itself. Each type will return a query keyed to its type.

The query object is chainable, until the `call` method is called. This will
return the results, unless a block is given, in which the results are passed to
the block and `call` returns `nil`. They query object can then also be reused to
find again, which will hit the cache if its enabled.

By default, the query will do a `:first` find.

### API methods

`in(<base string>)`: to set the Base DC for the query. Expects a String
argument.

`for(<:first|:all>)`: expects either `:first` or `:all` as the sole argument.

There are also syntactic sugar methods, `.first` and `.all` that are wrappers
for `.for(:first)` and `.for(:all)` respectively.

`where(<filters hash>)`: filters to search for. Will throw and `ArgumentError`
if the sole argument is not a Hash.

`includes(<attribute, attribute, ...>)`: a list of attributes to include with
the query. The query will still use any default attributes defined by the type
or in the config file.

`call`: excute the query and either return the results, or if a block is given,
pass the results to the block and return nil.

```ruby
query = ADI::User.query

query.first
     .where(samaccountname: 'juser')
     .includes('department', 'title')

query.call { |user| puts user.title }

ADI::Group.query.all.where(name: 'SomeGroups*').call.each do |group|
  puts group
end
```

## Attributes

You can specify which attributes you wish to return from a query call. This will
mostly be for User entries, but the `includes` Query API will apply a given
attributes parameter to any search. The User entry type has a default list of
attributes that will always be pulled, as they are the bare minimum of a user,
plus contain fields that will be used to check for disabled users and the like.

### User Default Attributes

```text
userAccountControl
lockoutTime
directReports
manager
samaccountname
mail
givenname
sn
displayname
```

## Caching

Queries for membership and group membership are based on the distinguished name
of objects. Doing a lot of queries, especially for a Rails app, is a sizable
slowdown. To alleviate the problem, there is a very basic cache for queries
based on an entry's `distinguishedname` value.

Caching is disabled by default, but can be turned on by a call to
`ADI::Base.enable_cache`. This cache will invalidate an entry if it is older
than 5 minutes (300 seconds) by default. The entire cache is checked for invalid
entries every 15 minutes (900 seconds), though this only happens if a single
entry is checked for invalidation. Meaning, there is no separate thread or
process.

The `timeout` and `check_interval` values can also be set in the config, under
the `cache` value hash.

## ADI Config

A valid ADI config contains at least the `server` key, which is what is passed
to `Net::LDAP` to connect to the Active Directory server.

The `attributes` key, which defines array of strings, per entry type (User,
Group, etc.) that must be returned when an entry of that type is searched for.
For example, if it is desired to return the 'department' attribute for a user,
define a `:user` key with an array of `['department']` and that key will always
be included when a User is loaded from Active Directory.

There can be an optional `cache` key that defines the `timeout` and
`check_interval` values if those are to be customized.

Note: If they attribute does not exist, it will not be returned and a nil result
will exist in its place.

See the Net::LDAP library for configuration options for connecting to Active
Directory.

### Example Config

```ruby
config = {
  server: {
    host: 'ad-server.example.org',
    port: 636,
    base: 'dc=example,dc=org',
    encryption: :simple_tls,
    auth: {
      method:   :simple,
      username: 'bind_user@example.org',
      password: 'password_for_bind_user'
    }
  },

  attributes: {
    user: ['department', 'title']
  },

  cache: {
    timeout:        300,
    check_interval: 900
  }
}
```

## Basic usage

```ruby
# Configure the ADI library with a config, like that above.
ADI::Base.setup(settings)

### Query Interface Usage

# Get the base User query
query = ADI::User.query

# Modify the base query to find the first user with the matching
# sAMAccountName, and include the Department and Title fields.
query.first
     .where(samaccountname: 'juser')
     .includes('department', 'title')

# Execute the query and pass the user, if found, into the block.
query.call { |user| puts user.title }

# Look for all groups matching the name string, printing them out.
ADI::Group.query.all.where(name: 'SomeGroups*').call.each do |group|
  puts group
end

### Legacy Find Usage

# Find all users.
ADI::User.find(:all)

# Find a specific user.
ADI::User.find(:first, :samaccountname => 'juser')

# Find a specific user with a one-time extra attribute.
ADI::User.find(:first, { :samaccountname => 'juser' }, ['title'])

# Find all groups.
ADI::Group.find(:all)

# Caching API
ADI::Base.enable_cache
ADI::Base.disable_cache
ADI::Base.caching?
```
