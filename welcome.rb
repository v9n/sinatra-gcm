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
require 'rack-flash'

use Rack::Flash

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

configure do
  set :logging, :true
  set :AUTHORIZE_KEY => 'AIzaSyAU1_3EdDZyKdo8oRY3vWdq3_B2iUblNGg'
 
  # same as `set :option, true`
  enable :option

  # same as `set :option, false`
  #disable :option  
  
  # you can also have dynamic settings with blocks
  set(:css_dir) { File.join(views, 'css') }
  enable :sessions  
  
  #Less.paths << settings.views
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

class Device
    include Mongoid::Document
    
    field :reg_id, :type => String
    field :email, :type => String
    field :os, :type => String, :default => 'android'    
end

class Log
  include Mongoid::Document
    
    field :body, :type => 'String'
    field :query_string, :type => 'String'
    field :param, :type => 'String' 
    field :t, :type => String, :default => 'device'
end


class Message
    include Mongoid::Document
    
    field :body, :type => 'String'
    field :url,  :type => 'String'
    field :send_at, :type => Array, :default => []
end



helpers do
  include Rack::Utils
  alias_method :h, :escape_html

  def nl2br(s)
    s.gsub(/\r?\n/, "<br />") 
  end
end

get '/' do
  messages = Message.all
  haml :index, :locals => {:messages => messages}  
end

get '/message/remove/:id' do |id|
  Message.find(id).delete 
  flash[:notice] = "Message is removed!"
  redirect '/'
end

post '/message/save' do
  Log.new({body: request.body.read, query_string: request.query_string}).save
  
  begin 
    message = Message.new({:body => params[:body], :url => params[:url]})
    message.save
    flash[:notice] = "Message saved!"
  rescue
    flash[:notice] = "Message cannot saved!"  
  end
  redirect '/'
end

get '/message/send' do
  Log.new({body: request.body.read, query_string: request.query_string}).save

  message = Message.new({:body => params[:body], :url => params[:url]})
  message.save
  redirect "/message/send/#{message.id}"
end

get '/message/send/:id' do |id|
  begin 
    m = Message.find(id)
  rescue Mongoid::Errors::DocumentNotFound
    flash[:notice] = "Invalid message to send"
    redirect '/' 
  end 

  registration_ids = Array.new
  devices = Device.all
  devices.each do |d|
    registration_ids.push(d.reg_id)
  end

  registration_ids = ["APA91bHUpmULOkmrThGmUr3Gg0XucMY-YMxtaOCiJFRkwE4yunJkcTgl-IPfzvBjMsWFHSAMZqwOV0mn8yWYjbzL90viU97mR1eBQKpE4-PwPApTnagZXniTIeyiInP73BD-Pb4CYijh3ko1_h9nwWplP1lADEJWXg", "APA91bE6qtP5G46xx1UIlNkocQaRpbsWt29fAldQQw8WOTvXg29-cc5q4kizOvbRsCcDobEk3vv681f545VB4PtL6lDvaME_sZs-rcD0YSyW7Q9hO5euMBEBeO0D6JidtV1R7gHvUvcrUjeslZmKzKsIKKE0-Z9bAg"]; 
  post_args = {
    :registration_ids => registration_ids,#["APA91bE6qtP5G46xx1UIlNkocQaRpbsWt29fAldQQw8WOTvXg29-cc5q4kizOvbRsCcDobEk3vv681f545VB4PtL6lDvaME_sZs-rcD0YSyW7Q9hO5euMBEBeO0D6JidtV1R7gHvUvcrUjeslZmKzKsIKKE0-Z9bAg"],
    :data => {
      :msg    => m.body,
      :url => m.url
    }
  }
  resp = RestClient.post 'https://android.googleapis.com/gcm/send', post_args.to_json, :Authorization => 'key=' + settings.AUTHORIZE_KEY, :content_type => :json, :accept => :json
  puts resp.inspect
  Log.new({:body => resp.inspect, :t => 'Message Sending'}).save

  m.send_at = [] if m.send_at.nil?
  m.send_at.push Time.now.to_i
  m.save  
  # puts m.inspect
  flash[:notice] = "Message is sent to Google GCM Server."
  redirect '/'   
end

get '/send_message' do
  Log.new({body: request.body.read, query_string: request.query_string}).save
  
  post_args = {
    :registration_ids => ["APA91bE6qtP5G46xx1UIlNkocQaRpbsWt29fAldQQw8WOTvXg29-cc5q4kizOvbRsCcDobEk3vv681f545VB4PtL6lDvaME_sZs-rcD0YSyW7Q9hO5euMBEBeO0D6JidtV1R7gHvUvcrUjeslZmKzKsIKKE0-Z9bAg"],
    :data => {
      :msg    => "Welcome to iCeeNee",
      :coupon => "iCeeNee"
    }
  }
  resp = RestClient.post 'https://android.googleapis.com/gcm/send', post_args.to_json, :Authorization => 'key=' + settings.AUTHORIZE_KEY, :content_type => :json, :accept => :json
  resp.inspect
  Log.new({body: resp.inspect}).save
  
end

get '/device' do
  devices = Device.all
  haml :device, :locals => {:devices => devices}    
end  

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

post '/register' do
  Log.new({param: params, body: request.body.read, query_string: request.query_string}).save
  puts params.inspect
  #curl -X POST -H 'Content-Type:application/json' -H 'Authorization:key=AIzaSyAU1_3EdDZyKdo8oRY3vWdq3_B2iUblNGg'  -d '{"registration_ids":["APA91bE6qtP5G46xx1UIlNkocQaRpbsWt29fAldQQw8WOTvXg29-cc5q4kizOvbRsCcDobEk3vv681f545VB4PtL6lDvaME_sZs-rcD0YSyW7Q9hO5euMBEBeO0D6JidtV1R7gHvUvcrUjeslZmKzKsIKKE0-Z9bAg"],"data":{"msg":"Welcome to iCeeNee","coupon":"iCeeNee"}}' https://android.googleapis.com/gcm/send
  if 0==Device.where(reg_id: params[:regId]).count
    device = Device.new({:reg_id => params[:regId], :email => params[:email],:os => params[:os].nil?? 'android':'ios'})
    device.save!
    "Saved"
  else 
    "existed"
  end
end

get '/remove_device/:name' do |name|
  Device.find(name).delete 
  flash[:notice] = "Device is removed!"
  redirect '/device'
end

get '/about' do
  "@kureikain"
end

get '/help' do
  "@Help Page"
end

get '/css/:style.css' do
  less params[:style].to_sym, :paths => ["public/css"], :layout => false
end