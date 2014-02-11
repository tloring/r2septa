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
      @data = SeptaR2.station_list.reverse
      haml :stations
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

    if ext =~ /json/
      return JSON.pretty_generate(r2.schedule_data) 
    else
      @title   = "#{stations[0].name}"
      @header  = "#{stations[0].name} >> #{stations[1].name} [#{Time.now.strftime("%l:%M:%S")}]"
      #@output += r2.schedule_text
      @data = r2.schedule_data
      haml :trains
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
    <meta content="width=device-width, maximum-scale=1.0, initial-scale=0.5, user-scalable=yes" name="viewport">
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

@@ stations

%ul{:style=>"font-family:monospace"}
  - @data.each do |station|
    %li= station

@@ trains

%p{:style=>"font-family:monospace"}= @header

%table{:style=>"font-family:monospace; width:100%"}
  - next_arrival = 0
  - @data.each_with_index do |train, index|
    - next_arrival += 1 if not train[:next_arrival].empty?
    - row_color = index.even? ? '#eee' : '#fff'
    - row_color = "#FFFFAA" if next_arrival == 1
    %tr{:style=>"background-color:#{row_color}"}
      %td{:align=>"right", :style=>"font-style:italic"}= "&nbsp;" + train[:time_before] + "&nbsp;"
      %td{:align=>"right", :style=>"font-weight:bold"}= "&nbsp;" + train[:time_origin] + "&nbsp;"
      %td{:align=>"right"}= "&nbsp;[" + train[:train_number] + "]&nbsp;"
      %td{:align=>"right"}= "&nbsp;" + train[:time_destination] + "&nbsp;"
      %td{:style=>"font-style:italic"}= "&nbsp;" + train[:time_after] + "&nbsp;"
      %td{:style=>"width:100px", :align=>"left"}= "&nbsp;" + train[:next_arrival] + "&nbsp;"
