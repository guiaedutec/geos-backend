# frozen_string_literal: true
require 'open-uri'

class UserMailer < Devise::Mailer
  include Rails.application.routes.url_helpers
  layout 'mailers/mailer'

  # usermail (confirmation_instructions)
  def send_confirmation_instructions(user, translation)
    @user = user
    @translation = translation
    mail(to: @user.email, from: ENV['MAIL_FROM'], subject: translation['subject'])
  end
  
  # usermail (reset_password)
  def send_reset_password_instructions(user, translation)
    @user = user
    @translation = translation
    mail(to: @user.email, from: ENV['MAIL_FROM'], subject: translation['subject'])
  end

  # usermail (invite)
  def sendt_invite(user, translation)
    @user = user
    @translation = translation
    puts "Sending email...."
    mail(to: @user.email, from: ENV['MAIL_FROM'], subject: translation['subject'])
  end

  # usermail (reset_password)
  def sendt_password_new_user(user, translation)
    raw, hashed = Devise.token_generator.generate(User, :reset_password_token) 
    user.reset_password_token   = hashed
    user.reset_password_sent_at = Time.now.utc
    user.save(validate: false)
    @user = user
    
    @token = raw
    @translation = translation
    mail(to: @user.email, from: ENV['MAIL_FROM'], subject: translation['subject'])
  end

  # usermail
  def send_response(user, response)
    @user = user
    @profile = user._profile.to_s
    @response_url = ENV['BACKEND_URL']+"/api/v1/survey/feedback/"+response.survey_id.to_param+"/"+response.id.to_param+"?access_token=" + user.authenticity_token.to_s
    mail(to: @user.email, from: ENV['MAIL_FROM'], subject: translation['subject'])
  end

end
