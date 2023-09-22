Gem::Specification.new do |s|
  s.name    = 'ADI'
  s.version = '1.0.0'

  s.required_ruby_version = '2.7.1+'

  if s.respond_to? :required_rubygems_version=
    s.required_rubygems_version = Gem::Requirement.new('>= 0')
  end

  s.authors          = ['Randy Carnahan']
  s.date             = '2023-09-15'
  s.description      = 'Active Directory Interface using Net::LDAP'
  s.email            = 'randy.carnahan@charter.com'
  s.extra_rdoc_files = ['README.md']

  s.files = [
    'README.md',
    'Rakefile',
    'VERSION',
    'adi.gemspec',
    'lib/adi.rb',
    'lib/adi/base.rb',
    'lib/adi/base/class_methods.rb',
    'lib/adi/base/class_variables.rb',
    'lib/adi/base/instance_methods.rb',
    'lib/adi/computer.rb',
    'lib/adi/container.rb',
    'lib/adi/field_type/binary.rb',
    'lib/adi/field_type/date.rb',
    'lib/adi/field_type/dn_array.rb',
    'lib/adi/field_type/group_dn_array.rb',
    'lib/adi/field_type/member_dn_array.rb',
    'lib/adi/field_type/password.rb',
    'lib/adi/field_type/timestamp.rb',
    'lib/adi/field_type/user_dn_array.rb',
    'lib/adi/group.rb',
    'lib/adi/member.rb',
    'lib/adi/user.rb'
  ]

  s.require_paths    = ['lib']
  s.rubygems_version = '1.6.2'

  s.summary = 'Microsoft Active Directory Interface.'

  s.add_runtime_dependency('net-ldap', ['>= 0.1.1'])
  s.add_dependency('timedcache')
end
