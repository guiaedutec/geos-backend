# Use Ruby 2.4.10 as base image
FROM ruby:2.7.2

ENV TZ America/Sao_Paulo

# Install essential Linux packages
RUN apt-get -y update -qq
RUN apt-get install -y build-essential git libpq-dev nodejs sudo unzip cron ntp tzdata

# Files created inside the container repect the ownership
RUN adduser --shell /bin/bash --disabled-password --gecos "" app \
  && adduser app sudo \
  && echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

RUN echo 'Defaults secure_path="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/local/bundle/bin"' > /etc/sudoers.d/secure_path
RUN chmod 0440 /etc/sudoers.d/secure_path

# Define where our application will live inside the image
ENV RAILS_ROOT /app

# Create application home. App server will need the pids dir so just create everything in one shot
RUN mkdir -p $RAILS_ROOT/tmp/pids

# Set our working directory inside the image
WORKDIR $RAILS_ROOT

# throw errors if Gemfile has been modified since Gemfile.lock
#RUN bundle config --global frozen 1

COPY Gemfile ./
RUN gem install bundler --no-document
RUN bundle install --no-binstubs --jobs $(nproc) --retry 3

#RUN ntpd -gq
RUN service ntp start
RUN ln -fs /usr/share/zoneinfo/$TZ /etc/localtime
RUN dpkg-reconfigure --frontend noninteractive tzdata

COPY . .

# Add a script to be executed every time the container starts.
COPY entrypoint.sh /usr/bin/
RUN chmod +x /usr/bin/entrypoint.sh
ENTRYPOINT ["entrypoint.sh"]