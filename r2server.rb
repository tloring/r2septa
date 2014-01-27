#!/usr/bin/env ruby

require 'sinatra/base'
require 'haml'
require './r2'

class SeptaR2Server < Sinatra::Base

  configure do
    enable :inline_templates
  end

  get '/' do
    claymont = Station.new                                                                                     
    claymont.name = "Claymont"                                                                                 
    claymont.time_before = 20                                                                                  
    claymont.time_after = 15                                                                                   
                                                                                                               
    thirtieth = Station.new                                                                                    
    thirtieth.name = "30th Street Station"                                                                     
    thirtieth.time_before = 15                                                                                 
    thirtieth.time_after = 10                                                                                  
                                                                                                               
    @output = ""
    r2 = SeptaR2.new claymont, thirtieth                                                                       
    @output += "#{claymont.name} >> #{thirtieth.name}\n\n"                                                           
    @output += "Next to Arrive\n\n"                                                                                  
    @output += r2.next                                                                                               
    @output += "Weekday Schedule\n\n"                                                                                
    @output += r2.schedule                                                                                           
    r2.flip!                                                                                                   
    @output += "#{thirtieth.name} >> #{claymont.name}\n\n"                                                           
    @output += "Next to Arrive\n\n"                                                                                  
    @output += r2.next                                                                                               
    @output += "Weekday Schedule\n\n"                                                                                
    @output += r2.schedule                

    @output += "Stations\n\n"                                                                                
    r2.station_list.reverse.map{|s| "+ #{s}"}.each do |station|
      @output += station
    end

    haml :index
  end

end

__END__

#
# Templates
#

@@ layout

%html
  %head
    %title R2
    <meta http-equiv="refresh" content="60">
  %body
    %p
      %tt= Time.now.strftime("%l:%M:%S")

    = yield

@@ index

%pre= @output

