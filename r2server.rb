#!/usr/bin/env ruby

require 'sinatra/base'
require 'haml'
require 'json'
require 'awesome_print'
require './r2'

ENV['TZ']='America/New_York'

class SeptaR2Server < Sinatra::Base

  configure do
    enable :inline_templates
  end

  before do
    content_type 'application/json'
  end

  get '/' do
    redirect "/claymont"
  end

  get '/R2_Newark.gif' do
    send_file("#{settings.root}/R2_Newark.gif")
  end

  post '/' do 
    @orig = Station.new
    @orig.name = URI::decode(params['orig_name'])
    @orig.time_before = params['orig_tminus'].to_i
    @orig.time_after = params['orig_tplus'].to_i

    @dest = Station.new
    @dest.name = URI::decode(params['dest_name'])
    @dest.time_before = params['dest_tminus'].to_i
    @dest.time_after = params['dest_tplus'].to_i

    r2 = SeptaR2.new @orig, @dest
    return JSON.pretty_generate(r2.schedule_data)
  end

  get '/route/:orig_name/:orig_tminus/:orig_tplus/:dest_name/:dest_tminus/:dest_tplus/:format' do
    @orig = Station.new
    @orig.name = URI::decode(params[:orig_name])
    @orig.time_before = params[:orig_tminus].to_i
    @orig.time_after = params[:orig_tplus].to_i

    @dest = Station.new
    @dest.name = URI::decode(params[:dest_name])
    @dest.time_before = params[:dest_tminus].to_i
    @dest.time_after = params[:dest_tplus].to_i

    r2 = SeptaR2.new @orig, @dest
    return JSON.pretty_generate(r2.schedule_data) if params[:format] == 'json'

    @title   = "#{@orig.name}"
    @output  = "#{@orig.name} >> #{@dest.name} [#{Time.now.strftime("%l:%M:%S")}]\n\n"
    @output += r2.schedule_text

    haml :index
  end

  get '/claymont*' do |ext|
    @orig = Station.new
    @orig.name = "Claymont"
    @orig.time_before = 20
    @orig.time_after = 15

    @dest = Station.new
    @dest.name = "30th Street Station"
    @dest.time_before = 15
    @dest.time_after = 10

    r2 = SeptaR2.new @orig, @dest
    return JSON.pretty_generate(r2.schedule_data) if ext == ".json"

    @title   = "#{@orig.name}"
    @output  = "#{@orig.name} >> #{@dest.name} [#{Time.now.strftime("%l:%M:%S")}]\n\n"
    @output += r2.schedule_text

    haml :index
  end

  get '/30th*' do |ext|
    @orig = Station.new
    @orig.name = "30th Street Station"
    @orig.time_before = 15
    @orig.time_after = 10

    @dest = Station.new
    @dest.name = "Claymont"
    @dest.time_before = 20
    @dest.time_after = 15

    r2 = SeptaR2.new @orig, @dest
    return JSON.pretty_generate(r2.schedule_data) if ext == ".json"

    @title   = "#{@orig.name}"
    @output  = "#{@orig.name} >> #{@dest.name} [#{Time.now.strftime("%l:%M:%S")}]\n\n"
    @output += r2.schedule_text

    haml :index
  end

  post '/stations' do
    return JSON.pretty_generate SeptaR2.station_list 
  end

  get '/stations*' do |ext|
    return JSON.pretty_generate SeptaR2.station_list if ext == '.json' 

    @title = "Stations"
    @output = ""
    SeptaR2.station_list.reverse.map{|s| "+ #{s}\n"}.each do |station|
      @output += station
    end

    haml :index
  end

end

__END__

@@ layout

%html
  %head
    %title #{@title}
    <meta http-equiv="refresh" content="60">
  %body
    %img{:src=>'/R2_Newark.gif'}
    %p
      %tt
        %a{href: "/claymont"}Claymont
        |
        %a{href: "/30th"}30th Street Station
        |
        %a{href: "/stations"}Stations

    = yield

@@ index

%pre= @output

