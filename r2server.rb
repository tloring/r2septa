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
    claymont.minutes_to = 20
    claymont.minutes_from = 15

    thirtieth = Station.new
    thirtieth.name = "30th Street Station"
    thirtieth.minutes_to = 15
    thirtieth.minutes_from = 10

    r2 = SeptaR2.new claymont, thirtieth

    @output = "\n    "
    @output += r2.next
    @output += r2.schedule
    r2.flip!
    @output += r2.next
    @output += r2.schedule

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
      %tt= Time.now

    = yield

@@ index

%pre= @output

