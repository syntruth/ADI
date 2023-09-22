Gem::Specification.new do |s|
  s.name    = 'adi'
  s.version = File.read('VERSION').strip
  s.license = 'GPL-3.0-or-later'

  s.required_ruby_version = '>= 2.7.1'

  s.authors  = ['Randy Carnahan']
  s.homepage = 'https://github.com/syntruth/ADI'
  s.date     = '2023-09-22'
  s.summary  = 'Active Directory Interface using Net::LDAP'
  s.email    = 'syntruth@dragonsbait.com'

  s.files = Dir['lib/**/*.rb']

  s.add_runtime_dependency 'net-ldap', '~> 0.1', '>= 0.1.0'
end
