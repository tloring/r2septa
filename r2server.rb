#!/usr/bin/env ruby

require 'sinatra/base'
require 'haml'
require 'json'
require 'awesome_print'
require './r2'

ENV['TZ']='America/New_York'

class SeptaR2Server < Sinatra::Base
  
  # Configuration

  configure do
    enable :inline_templates

    $claymont = Station.new
    $claymont.name = "Claymont"
    $claymont.time_before = 20
    $claymont.time_after = 15

    $thirtieth = Station.new
    $thirtieth.name = "30th Street Station"
    $thirtieth.time_before = 15
    $thirtieth.time_after = 10

    $stations = [$claymont, $thirtieth]
  end

  before do
    content_type 'application/json' if request.request_method == "POST"
  end

  # Logo 

  get '/R2_Newark.gif' do
    send_file("#{settings.root}/R2_Newark.gif")
  end

  # Station List

  get '/stations*' do |ext|
    if ext == '.json' 
      return JSON.pretty_generate SeptaR2.station_list 
    else
      @title = "Stations"
      @output = ""
      SeptaR2.station_list.reverse.map{|s| "+ #{s}\n"}.each do |station|
        @output += station
      end
      haml :index
    end
  end

  post '/stations' do
    return JSON.pretty_generate SeptaR2.station_list 
  end

  # Schedule

  get '/:station?' do |station|
    if params['station'] =~ /json/
      params['station'] = nil
      ext = "json" 
    end

    stations = $stations
    if params['station'].nil? 
      stations = $stations.reverse if Time.now.strftime("%P") == "pm" 
    else
      station, ext = params['station'].split('.')
      stations = $stations.reverse if station =~ /30th/ # need generic n/s or am/pm departure
    end
  
    r2 = SeptaR2.new(*stations)
    puts r2.schedule_data

    if ext =~ /json/
      return JSON.pretty_generate(r2.schedule_data) 
    else
      @title   = "#{stations[0].name}"
      @output  = "#{stations[0].name} >> #{stations[1].name} [#{Time.now.strftime("%l:%M:%S")}]\n\n"
      @output += r2.schedule_text
      haml :index
    end
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

end

__END__

@@ layout

%html
  %head
    %title #{@title}
    <meta http-equiv="refresh" content="60">
  %body
    %a{:href=>'/'}
      %img{:src=>'/R2_Newark.gif', :border=>0}
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

