source :rubygems
gemspec

if version = ENV['ACTIONPACK_VERSION']
  if version == 'master'
    gem 'actionpack', :github => 'rails/rails'
    gem 'activemodel', :github => 'rails/rails'
    gem 'journey', :github => 'rails/journey'
  else
    gem "actionpack", "~> #{version}"
  end
end
