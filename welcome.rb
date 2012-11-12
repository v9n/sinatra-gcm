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
	set :CLIENT_ID => 'd00b37e0fbf1488e8d49', :CLIENT_SECRET => '971ba392a08327aaa02b598ac71bc9258c1314cd'
 
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

get '/do' do
	"Welcome to Sinatra GCM"

r = /<([a-zA-Z0-9]*)>/
s = "This is a <psa><strong>test</strong> <a title=\"sasa\">test string<p>"
c = s.scan r
 "result =" << c.inspect
end


post '/do3' do
  result = Array.new
  result << params[:testString]
  result.inspect
end

get '/about' do
  "@kureikain"
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

get '/mine' do
  url = URI.parse('https://api.github.com/users/kureikain/gists')
  data = RestClient.get 'https://api.github.com/users/kureikain/gists'
  #resp, data = Net::HTTP.get_response(url)

  "Response is #{data.inspect}"
end  

get '/delete/:gist_id' do
  url = "https://api.github.com/gists/:#{params[:gist_id]}"
  resp = RestClient.delete url
  resp.inspect
end 

get '/create' do
  url = 'https://api.github.com/gists?access_token=2ed1d303c6d9db90e9be50b706983356fe5e7227'
  post_args = {
    :description  => "Second Test Sigular",
    :public       => true,
    :files        => {
      "sigular.json" => {
          :content => "{name: test, regex: sa}"
      },
      "second.txt" => {
        :content => "Ngay hom qua o lai trong ruon "
      
      }
    }
  }
  resp = RestClient.post url, post_args.to_json, :content_type => :json, :accept => :json
  resp.inspect
end  

get '/send_message' do 
  post_args = {
    :registration_ids => ["1"],
    :data => {
      :msg    => "Welcome to iCeeNee",
      :coupon => "iCeeNee"
    }
  }
  resp = RestClient.post 'https://android.googleapis.com/gcm/send', post_args.to_json, :Authorization => 'key=AIzaSyBnio3IpScnAR_W_61UArwWMbPyym9ao7M',:content_type => :json, :accept => :json
  resp.inspect
end


# Handling device registration. Storing registrationId into a mongo db
# 
#
#

post 'new_device' do
end

#
# 2ed1d303c6d9db90e9be50b706983356fe5e7227
#Your OAuth access token: 2ed1d303c6d9db90e9be50b706983356fe5e7227
#Your extended profile data: {"html_url"=>"https://github.com/kureikain", "type"=>"User", "location"=>"San Jose, California, USA", "company"=>"Axcoto", "gravatar_id"=>"659d0c8387cefd176347beef316688cd", "public_repos"=>42, "login"=>"kureikain", "following"=>99, "blog"=>"http://axcoto.com/", "public_gists"=>31, "hireable"=>true, "followers"=>10, "name"=>"Vinh Quốc Nguyễn", "avatar_url"=>"https://secure.gravatar.com/avatar/659d0c8387cefd176347beef316688cd?d=https://a248.e.akamai.net/assets.github.com%2Fimages%2Fgravatars%2Fgravatar-140.png", "email"=>"kureikain@gmail.com", "bio"=>"Web developer who loves to work with both of back-end, front-end stuff and even sys admin too. Thing changed so much since the first day I touch to that kind of machine.\r\n", "url"=>"https://api.github.com/users/kureikain", "id"=>49754, "created_at"=>"2009-01-27T21:11:00Z"}

get '/session/s' do
  session[:user] = 'kureikain'
end

get '/session' do
  "session is #{session.inspect}"
end

get '/auth/github' do
  url = client.auth_code.authorize_url(:redirect_uri => redirect_uri, :scope => 'gist')
  puts "Redirecting to URL: #{url.inspect}"
  redirect url
end

get '/auth/github/callback' do
  puts params[:code]
  begin
    access_token = client.auth_code.get_token(params[:code], :redirect_uri => redirect_uri)
    user = JSON.parse(access_token.get('/user').body)
    session[:token] = access_token.token;
    session[:user] = Hash.new(nil);
 
    session[:login] = user[:login];
    session[:user][:email] = user[:email];
    session[:user][:id] = user[:id];
    "<p>Your OAuth access token: #{access_token.token}</p><p>Your extended profile data:\n#{user.inspect}</p>"
  rescue OAuth2::Error => e
    %(<p>Outdated ?code=#{params[:code]}:</p><p>#{$!}</p><p><a href="/auth/github">Retry</a></p>)
  end
end

def redirect_uri(path = '/auth/github/callback', query = nil)
  #uri = URI.parse(request.url)
  uri = URI.parse(url(path))
  uri.path = path
  uri.query = query
  uri.to_s
end