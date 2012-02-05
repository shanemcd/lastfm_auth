require 'sinatra'
require 'digest/md5'
require 'faraday'

enable :sessions

key = '904ad91c2e8da35f16b24510d8c38917'
secret = '73152c997b0c5880ed5bd22cbbb5aa87'
callback = "http://localhost:9393/auth/lastfm/callback"

conn = Faraday.new(:url => 'http://ws.audioscrobbler.com/2.0/') do |builder|
  builder.use Faraday::Request::UrlEncoded
  builder.use Faraday::Response::Logger     
  builder.use Faraday::Adapter::NetHttp
end

def get_session_key(key, token, signature)
  response = conn.get("?method=auth.getSession&api_key=#{key}&token=#{token}&api_sig=#{signature}")
  s = response.body
end

request_uri = "http://www.last.fm/api/auth/?api_key=#{key}&cb=#{callback}"

def auth_user
  redirect request_uri
end

helpers do
  def current_user
    @current_user ||= session["user"]
  end
end

get '/' do
  erb :index
end

get '/auth/lastfm/callback' do
  session["user"] = params[:token]
  token = params[:token]
  signature = Digest::MD5.hexdigest("api_key#{key}methodauth.getSessiontoken#{token}#{secret}")
  get_session_key(key, token, signature)
  redirect '/'
end

get '/sign_in' do
  redirect request_uri
end


get '/sign_out' do
  session["user"] = nil
  redirect '/'
end