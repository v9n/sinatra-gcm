# encoding: utf-8
require 'sinatra'
require 'json'
require 'haml'
require 'net/http'
require 'uri'
require 'open-uri'
require 'oauth2'
require 'less'
require 'rest-client'
require 'mongo'
require 'mongoid'

class String
  def scan2(regexp)
    names = regexp.names
    if (names.count>0)
      scan(regexp).collect do |match|
        Hash[names.zip(match)]
      end
    else
      scan regexp
    end  
  end
end

class Device
    include Mongoid::Document
    
    field :reg_id, :type => String
end

class Log
  include Mongoid::Document
    
    field :body, :type => String
    field :query_string, :type => String
    field :param, :type => String 
end


Mongoid.configure do |config|
    if ENV['MONGOLAB_URI']
      conn = Mongo::Connection.from_uri(ENV['MONGOLAB_URI'])
      uri = URI.parse(ENV['MONGOLAB_URI'])
      config.master = conn.db(uri.path.gsub(/^\//, ''))
    else
      config.master = Mongo::Connection.from_uri("mongodb://localhost:27017").db('device')
    end
end

configure do
	set :logging, :true
	set :AUTHORIZE_KEY => 'AIzaSyAU1_3EdDZyKdo8oRY3vWdq3_B2iUblNGg'
 
  # same as `set :option, true`
  enable :option

  # same as `set :option, false`
  disable :option	
	
  # you can also have dynamic settings with blocks
  set(:css_dir) { File.join(views, 'css') }
	enable :sessions  
  
  #Less.paths << settings.views
end

helpers do
  include Rack::Utils
  alias_method :h, :escape_html

  def nl2br(s)
    s.gsub(/\r?\n/, "<br />") 
  end
end

get '/' do		
	haml :index, :locals => {}
end

get '/css/:style.css' do
	less params[:style].to_sym, :paths => ["public/css"], :layout => false
end

get '/about' do
  "@kureikain"
end

get '/pag' do
  "sasasas"
end

get '/help' do
  "@Help Page"
end

def client
  OAuth2::Client.new(settings.CLIENT_ID, settings.CLIENT_SECRET,
                     :ssl => {:ca_file => '/etc/ssl/ca-bundle.pem'},
                     :site => 'https://api.github.com',
                     :authorize_url => 'https://github.com/login/oauth/authorize',
                     :token_url => 'https://github.com/login/oauth/access_token')
end


get '/send_message' do 
  post_args = {
    :registration_ids => ["APA91bE6qtP5G46xx1UIlNkocQaRpbsWt29fAldQQw8WOTvXg29-cc5q4kizOvbRsCcDobEk3vv681f545VB4PtL6lDvaME_sZs-rcD0YSyW7Q9hO5euMBEBeO0D6JidtV1R7gHvUvcrUjeslZmKzKsIKKE0-Z9bAg"],
    :data => {
      :msg    => "Welcome to iCeeNee",
      :coupon => "iCeeNee"
    }
  }
  resp = RestClient.post 'https://android.googleapis.com/gcm/send', post_args.to_json, :Authorization => 'key=' + settings.AUTHORIZE_KEY, :content_type => :json, :accept => :json
  resp.inspect
end


# Handling device registration. Storing registrationId into a mongo db. Check if existed before inserting.
get '/register/:id' do |id|
  Log.new({body: request.body.read, query_string: request.query_string}).save
  
  #curl -X POST -H 'Content-Type:application/json' -H 'Authorization:key=AIzaSyAU1_3EdDZyKdo8oRY3vWdq3_B2iUblNGg'  -d '{"registration_ids":["APA91bE6qtP5G46xx1UIlNkocQaRpbsWt29fAldQQw8WOTvXg29-cc5q4kizOvbRsCcDobEk3vv681f545VB4PtL6lDvaME_sZs-rcD0YSyW7Q9hO5euMBEBeO0D6JidtV1R7gHvUvcrUjeslZmKzKsIKKE0-Z9bAg"],"data":{"msg":"Welcome to iCeeNee","coupon":"iCeeNee"}}' https://android.googleapis.com/gcm/send
  if 0==Device.where(reg_id: id).count
    device = Device.new({:reg_id => id})
    device.save!
    "Saved"
  else 
    "existed"
  end
end

post '/register' do |id|
  Log.new({param: params.to_str, body: request.body.read, query_string: request.query_string}).save
  
  #curl -X POST -H 'Content-Type:application/json' -H 'Authorization:key=AIzaSyAU1_3EdDZyKdo8oRY3vWdq3_B2iUblNGg'  -d '{"registration_ids":["APA91bE6qtP5G46xx1UIlNkocQaRpbsWt29fAldQQw8WOTvXg29-cc5q4kizOvbRsCcDobEk3vv681f545VB4PtL6lDvaME_sZs-rcD0YSyW7Q9hO5euMBEBeO0D6JidtV1R7gHvUvcrUjeslZmKzKsIKKE0-Z9bAg"],"data":{"msg":"Welcome to iCeeNee","coupon":"iCeeNee"}}' https://android.googleapis.com/gcm/send
  if 0==Device.where(reg_id: params[:regId]).count
    device = Device.new({:reg_id => params[:regId]})
    device.save!
    "Saved"
  else 
    "existed"
  end
end