require 'sinatra'
require 'digest/md5'
require 'faraday'
require 'faraday_middleware'

enable :sessions

key = ENV['LASTFM_KEY']
secret = ENV['LASTFM_SECRET']

callback = "http://localhost:9393/auth/lastfm/callback"
request_uri = "http://www.last.fm/api/auth/?api_key=#{key}&cb=#{callback}"

helpers do
  def current_user
    @current_user ||= session["user"]
  end
end

def make_signature(key, token, secret)
  Digest::MD5.hexdigest("api_key#{key}methodauth.getSessiontoken#{token}#{secret}")
end

def get_session(key, token, signature)
  conn = Faraday.new(:url => 'http://ws.audioscrobbler.com') do |builder|
    builder.use Faraday::Request::UrlEncoded
    builder.use Faraday::Response::Logger     
    builder.use Faraday::Adapter::NetHttp
    builder.use Faraday::Response::ParseJson
  end

  conn.get "/2.0/?method=auth.getSession&api_key=#{key}&token=#{token}&api_sig=#{signature}&format=json"
end

get '/' do
  erb :index
end

get '/auth/lastfm/callback' do
  token = params[:token]
  signature = make_signature(key, token, secret)
  response = get_session(key, token, signature)
  r = response.body
  session["user"] = r["session"]["name"]
  session["key"] = r["session"]["key"]
  redirect '/'
end

get '/sign_in' do
  redirect request_uri
end


get '/sign_out' do
  session["user"] = nil
  redirect '/'
end