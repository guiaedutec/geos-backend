# frozen_string_literal: true
require 'resque/server'

Rails.application.routes.draw do
  mount Resque::Server.new, at: '/resque'
  get '/admin', to: 'pages#home'

  scope '/admin' do
    resources :survey_responses, path: 'devolutivas' do
      collection do
        get :issues, path: 'problematicas'
      end

      member do
        post :refetch, path: 'sincronizar'
      end
    end
    resources :users, path: 'usuarios'
    get '/valid_principal', to: 'users#valid_principal', as: 'validPrincipal', defaults: {format: 'json'}
    get '/citiesbystate', to: 'cities#getCities', as: 'getCities', defaults: {format: 'json'}
    get '/getschools', to: 'schools#getSchools', as: 'getSchools', defaults: {format: 'json'}
    get '/getuserinfo', to: 'users#getUserInfo', as: 'getUserInfo', defaults: {format: 'json'}
    resources :regions, path: 'regioes'
    # resources :schools, path: 'escolas'
    resources :states, path: 'estados'
    resources :cities, path: 'cidades'
    resources :survey_questions, path: 'questoes'
    resources :survey_sections, path: 'secoes'
    resources :surveys, path: 'questionarios'
    resources :spread_sheets, path: 'inspirese', only: [:index]
    post '/rating', to: 'rating#index', as: 'ratingProject', defaults: {format: 'json'}
    resources :activities, path: 'atividades'
    post '/survey_question', to: 'survey_questions#new_question', as: 'SurveyQuestion', defaults: {format: 'json'}
    get '/edit_question', to: 'survey_questions#edit_question', as: 'EditQuestion', defaults: {format: 'json'}
    get '/search', to: 'users#search', as: 'searchUsers'

  end

  root to: 'home#guiaedutec'

  devise_for :users,
             controllers: { sessions: 'users/sessions', passwords: 'users/passwords', registrations: 'users/registrations',
                            confirmations: 'users/confirmations' }

  namespace :api do
    namespace :v1 do

      get '/schools/profile/', to: 'api#test_get_schools_by_profile', as: 'test_get_schools_by_profile',
                               defaults: {format: 'json'}

      post '/admin_country/edit/:id', to: 'users#edit_admin_country', as: 'edit_admin_country'
      post '/admin_country/delete/:id', to: 'users#delete_admin_country', as: 'delete_admin_country'
      get '/admin_country/:id', to: 'users#get_admin_country_by_id', as: 'get_admin_country_by_id',
                                defaults: {format: 'json'}
      post '/admin_country/save', to: 'users#save_admin_country', as: 'save_admin_country'
      get '/admin_country_list', to: 'users#admin_country_list', as: 'admin_country_list', defaults: {format: 'json'}

      post '/school/edit/:id', to: 'schools#edit_school', as: 'edit_school'
      post '/school/delete/:id', to: 'schools#delete_school', as: 'delete_school'
      get '/school/:id', to: 'schools#get_school_by_id', as: 'get_school_by_id', defaults: {format: 'json'}
      post '/school/save', to: 'schools#save_school', as: 'save_school'
      get '/schools/', to: 'api#schools', as: 'schools', defaults: {format: 'json'}

      post '/institution/edit/:id', to: 'institutions#edit_institution', as: 'edit_institution'
      post '/institution/delete/:id', to: 'institutions#delete_institution', as: 'delete_institution'
      get '/institution/:id', to: 'institutions#get_institution_by_id', as: 'get_institution_by_id',
                              defaults: {format: 'json'}
      post '/institution/save', to: 'institutions#save_institution', as: 'save_institution'
      get '/institutions/', to: 'api#institutions', as: 'institutions', defaults: {format: 'json'}

      post '/country/edit/:id', to: 'countries#edit_country', as: 'edit_country'
      post '/country/delete/:id', to: 'countries#delete_country', as: 'delete_country'
      get '/country/:id', to: 'countries#get_country_by_id', as: 'get_country_by_id', defaults: {format: 'json'}
      post '/country/save', to: 'countries#save_country', as: 'save_country'
      match '/country.csv' => 'api#country_csv', via: :get, defaults: { format: :csv }

      post '/province/edit/:id', to: 'provinces#edit_province', as: 'edit_province'
      post '/province/delete/:id', to: 'provinces#delete_province', as: 'delete_province'
      get '/province/:id', to: 'provinces#get_province_by_id', as: 'get_province_by_id', defaults: {format: 'json'}
      post '/province/save', to: 'provinces#save_province', as: 'save_province'

      post '/state/edit/:id', to: 'states#edit_state', as: 'edit_state'
      post '/state/delete/:id', to: 'states#delete_state', as: 'delete_state'
      get '/state/:id', to: 'states#get_state_by_id', as: 'get_state_by_id', defaults: {format: 'json'}
      post '/state/save', to: 'states#save_state', as: 'save_state'

      post '/city/edit/:id', to: 'cities#edit_city', as: 'edit_city'
      post '/city/delete/:id', to: 'cities#delete_city', as: 'delete_city'
      get '/city/:id', to: 'cities#get_city_by_id', as: 'get_city_by_id', defaults: {format: 'json'}
      post '/city/save', to: 'cities#save_city', as: 'save_city'

      get '/langs/', to: 'languages#get_langs', as: 'get_langs', defaults: {format: 'json'}
      post '/language/', to: 'languages#save_language', as: 'save_language'
      post '/schools/upload/', to: 'schools#upload_school_csv', as: 'upload_school_csv'
      get '/translation/:lang', to: 'translations#get_translation_by_lang', as: 'get_translation_by_lang',
                                defaults: {format: 'json'}
      get '/language/langs/', to: 'languages#get_langs_translation', as: 'get_langs_translation',
                              defaults: {format: 'json'}
      post '/translation/', to: 'translations#save_translation', as: 'save_translation'

      post '/setup/', to: 'parameters#save_parameters', as: 'save_parameters'
      get '/setup/', to: 'parameters#get_parameters', as: 'get_parameters',
                                defaults: {format: 'json'}


      get :countries, to: 'api#countries', as: :countries
      get :provincies, to: 'api#provincies', as: :provincies
      get :states, to: 'api#states',  as: :states
      get :cities, to: 'api#cities',  as: :cities

      get :get_email_by_id, to: 'users#get_email_by_id', as: :get_email_by_id
      post :resend_invite, to: 'api#resend_invite', as: :resend_invite, defaults: {format: 'json'}

      get :survey_response, to: 'api#survey_response', as: :survey_response

      post '/was_notified', to: 'api#was_notified', as: 'was_notified', defaults: {format: 'json'}
      post '/accepted_term', to: 'api#accepted_term', as: 'accepted_term', defaults: {format: 'json'}

      # old devolutives
      get '/old_survey_response', to: 'api#survey_old_response'
      get :regions, to: 'api#regions', as: :regions
      get :spreadsheets, to: 'api#spreadsheets',  as: :spreadsheets
      get :survey_answers_query, to: 'api#survey_answers_query', as: :survey_answers_query
      get :survey_answers_cicle, to: 'api#survey_answers_cicle', as: :survey_answers_cicle
      get :survey_answers_results, to: 'api#survey_answers_results', as: :survey_answers_results
      match :survey_answer, to: 'api#survey_answer', as: :survey_answer, via: [:get, :post]
      get :print_survey_url, to: 'api#print_survey_url', as: :print_survey
      get :school_plans_answers, to: 'api#school_plans_answers', as: :school_plans_answers
      get :school_plans_results, to: 'api#school_plans_results', as: :school_plans_results
      patch :change_password, to: 'api#change_password', as: :change_password
      patch :change_user_password, to: 'api#change_user_password', as: :change_user_password
      get :valid_schools, to: 'schools#valid_schools', as: :valid_schools, defaults: { format: 'json' }
      get :has_answered_schools, to: 'schools#has_answereds'
      get :has_sampled_schools, to: 'schools#has_samples'
      get :user_school, to: 'schools#user_school', as: :user_school, defaults: { format: 'json' }
      get :user_institution, to: 'api#user_institution', as: :user_institution, defaults: { format: 'json' }
      get :map_data, to: 'schools#map_data', as: :map_data, defaults: { format: 'json' }
      
      get '/schools_diagnostic_data', to: 'schools#schools_diagnostic_data', as: :schools_diagnostic_data, defaults: { format: 'json' }
      get '/export_schools_microdata', to: 'schools#export_schools_microdata', as: :export_schools_microdata, defaults: {format: 'json'}
      get '/export_teachers_microdata', to: 'schools#export_teachers_microdata', as: :export_teachers_microdata, defaults: {format: :csv}
      get '/export_microdata_get_file/:id', to: 'schools#export_microdata_get_file', as: :export_microdata_get_file, defaults: {format: :csv}
      get '/export_jobs_microdata', to: 'api#export_jobs_microdata', as: :export_jobs_microdata, defaults: {format: 'json'}

      post '/upload_spread_scheets_school', to: 'spread_scheets_school#upload_schools',  as: :spreadsheetschools,
                                            defaults: {format: 'json'}
      post '/render_stepone_upload', to: 'spread_scheets_school#render_stepone_upload',
                                     as: :spreadsheetschools_render_stepone_upload,  defaults: {format: 'json'}
      get :list_all_activities, to: 'activity_api#list_all_activities'
      post :save_user_activity, to: 'activity_api#save_user_activity'
      get :list_all_user_activities, to: 'activity_api#list_all_user_activities'
      get '/survey_responses_statistics', to: 'survey_responses#responses_statistics', as: 'statistics',
                                          defaults: {format: 'json'}
      get '/survey_responses_details', to: 'survey_responses#responses_details', as: 'details',
                                       defaults: {format: 'json'}

      get '/retrieve_seven_pages_common_devolutive', to: 'feedback#retrieve_seven_pages_common_devolutive',
                                                     defaults: {format: 'json'}
      get '/retrieve_footer_page_common_devolutive', to: 'feedback#retrieve_footer_page_common_devolutive',
                                                     defaults: {format: 'json'}

      get '/feedbacks/:id_survey', to: 'feedback#get_all_by_survey', defaults: {format: 'json'}
      post '/save_feedback', to: 'feedback#save', defaults: {format: 'json'}
      post '/update_feedback', to: 'feedback#update_feedback', defaults: {format: 'json'}
      post '/delete_feedback', to: 'feedback#delete', defaults: {format: 'json'}
      get '/edit_feedback/:id', to: 'feedback#edit', defaults: {format: 'json'}
      get '/save_footer_feedback/:id', to: 'feedback#save_footer', defaults: {format: 'json'}
      post '/upload_files_feedback', to: 'feedback#upload_files', defaults: {format: 'json'}
      post '/remove_file', to: 'feedback#remove_file', defaults: {format: 'json'}
      get '/find_images_school', to: 'feedback#find_images_school', as: 'find_images_school', defaults: {format: 'json'}
      get '/validate_principal', to: 'managers#valid_principal', as: 'validPrincipal', defaults: {format: 'json'}
      post '/upload_term', to: 'managers#upload_files', defaults: {format: 'json'}
      get '/list_managers', to: 'users#list_managers', as: 'list_managers', defaults: {format: 'json'}
      post '/change_lock', to: 'users#change_lock', defaults: {format: 'json'}

      post '/upload_spread_scheets_manager', to: 'spread_scheets_manager#upload_manageres',
                                             as: :spreadsheetmanageres,  defaults: {format: 'json'}
      post '/render_stepone_upload_manager', to: 'spread_scheets_manager#render_stepone_upload',
                                             as: :spreadsheetmanageres_render_stepone_upload,  defaults: {format: 'json'}

      get '/retrieve_all_states', to: 'dashboard#retrieve_all_states', as: 'retrieve_all_states',
                                  defaults: {format: 'json'}
      get '/retrieve_cities_by_state/:id', to: 'dashboard#retrieve_cities_by_state', as: 'retrieve_cities_by_state',
                                           defaults: {format: 'json'}
      post '/retrieve_dashboard', to: 'dashboard#index', as: 'retrieve_dashboard', defaults: {format: 'json'}
      get '/save_dashboard', to: 'dashboard#create', defaults: {format: 'json'}
      post '/total_of_networks', to: 'dashboard#total_of_networks', defaults: {format: 'json'}
      post '/amount_of_networks', to: 'dashboard#amount_of_networks', defaults: {format: 'json'}
      post '/number_of_schools', to: 'dashboard#number_of_schools', defaults: {format: 'json'}
      post '/number_of_schools_with_responses', to: 'dashboard#number_of_schools_with_responses',
                                                defaults: {format: 'json'}
      post '/number_of_responses', to: 'dashboard#number_of_responses', defaults: {format: 'json'}
      post '/completed_networks', to: 'dashboard#completed_networks', defaults: {format: 'json'}

      get '/indicators_table', to: 'survey_responses#indicators_table', as: 'indicators_table',
                               defaults: {format: 'json'}
      get '/indicators_details/:page/:size', to: 'survey_responses#indicators_details', as: 'indicators_details',
                                             defaults: {format: 'json'}
      resources :schools, only: [:update] do
        member { get :survey_response }
      end
      # resources :schools, path: 'schools'
      get :school_regionals, to: 'schools#regionals'



      defaults format: :json do
        resources :survey do
          collection do
            get :total_responses, to: 'survey_responses#total_responses', as: :total_responses
            get :surveys_list
            post 'update_survey', to: 'survey#update_survey', defaults: {format: 'json'}
            get 'questions/:id', to: 'survey_questions#questions_list'
            post 'update_section', to: 'survey_questions#update_section', defaults: {format: 'json'}
            post 'update_question', to: 'survey_questions#update_question', defaults: {format: 'json'}
            get 'responses_user/:id', to: 'survey_responses#survey_responses'
            post 'respond/:id_survey/:id_response', to: 'survey_responses#respond_answers'
            post 'generate_scores/:id_survey/:id_response', to: 'api#generate_scores'
            get 'feedback/:id_survey/:id_response', to: 'api#survey_feedback'

            get 'all_responses/:id_survey', to: 'survey_responses#all_responses'
            get '/retrieve_all_devolutive/:id_survey', to: 'feedback#retrieve_all_devolutive',
                                                       defaults: {format: 'json'}
            post 'schedule/:id_survey', to: 'survey_schedule#date_survey', as: :date_survey,
                                        defaults: { format: 'json' }

            resources :answers, path: 'respostas'
            get :answers, to: 'api#survey_answers', as: :answers
            get :result_per_dimension, to: 'survey_responses#result_per_dimension', as: 'result_per_dimension',
                                       defaults: {format: 'json'}
            get :result_self_evaluation_details, to: 'survey_responses#result_self_evaluation_details',
                                                 as: 'result_self_evaluation_details', defaults: {format: 'json'}
            get :result_self_evaluation_summary, to: 'survey_responses#result_self_evaluation_summary',
                                                 as: 'result_self_evaluation_summary', defaults: {format: 'json'}
            get :distribution_by_area, to: 'survey_responses#distribution_by_area', as: 'distribution_by_area',
                                       defaults: {format: 'json'}
            get :responses_self_evaluation_demography, to: 'survey_responses#responses_self_evaluation_demography',
                                                       as: 'responses_self_evaluation_demography', defaults: {format: 'json'}
            get :list_teachers_by_competences, to: 'survey_responses#list_teachers_by_competences',
                                               as: 'list_teachers_by_competences', defaults: {format: 'json'}
            get :result_avg, to: 'survey_responses#result_avg', as: 'result_avg', defaults: {format: 'json'}
            get :result_questions_per_dimension, to: 'survey_responses#result_questions_per_dimension',
                                                 as: 'result_questions_per_dimension', defaults: {format: 'json'}
            get :answers_details, to: 'api#survey_answers_details', as: :survey_answers_details
          end
        end

        resources :plan do
          collection do
            get :thematics, to: 'plans#thematics', as: 'thematics',  defaults: {format: 'json'}
          end
        end
      end

      # remover
      # get :find_date_survey, to: 'survey_schedule#find_date_survey', as: :find_date_survey, defaults: { format: 'json' }
      get '/has_old_survey_response', to: 'api#has_survey_old_response'
      get :user_answered, to: 'schools#user_answered', as: :user_answered, defaults: { format: 'json' }
      get 'questions_managed', to: 'survey_questions#index'
      get '/survey_responses_user', to: 'survey_responses#responses', as: 'Response', defaults: {format: 'json'}
      post '/survey_responses_respond',  to: 'survey_responses#respond_answers', as: 'surveyanswers',
                                         defaults: {format: 'json'}
      get '/generate_scores', to: 'api#generate_scores', as: 'generate_scores', defaults: {format: 'json'}
      # get '/re_generate_scores', to: 'api#re_generate_scores', as: 're_generate_scores', :defaults => {:format =>'json'}
      get :survey_feedback, to: 'api#survey_feedback', as: :survey_feedback




      # managers front-end management
      resources :managers, path: 'managers'

      # users front-end management
      resources :users, path: 'users'

      # survey front-end management
      get '/survey_questions/multiple', to: 'survey_questions#index', as: 'survey_index_multiple'
      get '/survey_questions/multiple_manager', to: 'survey_questions#index_manager',
                                                as: 'survey_index_multiple_manager'
      put '/survey_questions/multiple', to: 'survey_questions#save_multiple', as: 'survey_save_multiple'


      resources :users, only: [] do
        member { get :survey_response }
      end

      resources :surveys, defaults: { format: 'json' }
    end
  end

  get '/survey_response_example', to: 'api/v1/schools#survey_example'
end
