#!/usr/bin/env ruby

require 'sinatra/base'
require 'haml'
require './r2'

class SeptaR2Server < Sinatra::Base

  configure do
    enable :inline_templates
  end

  get '/' do
    @orig = Station.new
    @orig.name = "Claymont"
    @orig.time_before = 20
    @orig.time_after = 15

    @dest = Station.new
    @dest.name = "30th Street Station"
    @dest.time_before = 15
    @dest.time_after = 10

    @title = "R2"

    r2 = SeptaR2.new @orig, @dest

    @output  = "#{@orig.name} >> #{@dest.name}\n\n"
    #@output += "Next to Arrive\n\n"
    #@output += r2.next
    #@output += "Weekday Schedule\n\n"
    @output += r2.schedule

    r2.flip!
    @output += "#{@orig.name} >> #{@dest.name}\n\n"
    #@output += "Next to Arrive\n\n"
    #@output += r2.next
    #@output += "Weekday Schedule\n\n"
    @output += r2.schedule

    @output += "Stations\n\n"
    SeptaR2.station_list.reverse.map{|s| "+ #{s}\n"}.each do |station|
      @output += station
    end

    haml :index
  end

  get '/claymont' do
    @orig = Station.new
    @orig.name = "Claymont"
    @orig.time_before = 20
    @orig.time_after = 15

    @dest = Station.new
    @dest.name = "30th Street Station"
    @dest.time_before = 15
    @dest.time_after = 10

    r2 = SeptaR2.new @orig, @dest

    @title   = "#{@orig.name}"
    @output  = "#{@orig.name} >> #{@dest.name}\n\n"
    #@output += "Next to Arrive\n\n"
    #@output += r2.next
    #@output += "Weekday Schedule\n\n"
    @output += r2.schedule

    haml :index
  end

  get '/30th' do
    @orig = Station.new
    @orig.name = "30th Street Station"
    @orig.time_before = 15
    @orig.time_after = 10

    @dest = Station.new
    @dest.name = "Claymont"
    @dest.time_before = 20
    @dest.time_after = 15

    r2 = SeptaR2.new @orig, @dest

    @title   = "#{@orig.name}"
    @output  = "#{@orig.name} >> #{@dest.name}\n\n"
    #@output += "Next to Arrive\n\n"
    #@output += r2.next
    #@output += "Weekday Schedule\n\n"
    @output += r2.schedule

    haml :index
  end

  get '/stations' do
    @title = "Stations"
    @output = "#{@title}\n\n"
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
    %p
      %tt
        = Time.now.strftime("%l:%M:%S")
        %a{href: "/claymont"}Claymont
        |
        %a{href: "/30th"}30th Street Station
        |
        %a{href: "/stations"}Stations

    = yield

@@ index

%pre= @output

