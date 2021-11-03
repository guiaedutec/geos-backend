RSpec.configure do |config|
  config.before(:each) do
    DatabaseCleaner.orm = 'mongoid'
    DatabaseCleaner.strategy = :truncation
    DatabaseCleaner.clean
  end
end
