web: bundle exec puma -C config/puma.rb
scheduler: DYNAMIC_SCHEDULE=true bundle exec rake resque:scheduler
worker: bundle exec rake jobs:work
