#!/usr/bin/env ruby

require 'sinatra/base'
require 'haml'
require './r2'

class SeptaR2Server < Sinatra::Base

  configure do
    enable :inline_templates
  end

  get '/' do
    @output = "\n    "
    r2 = SeptaR2.new :claymont, :thirtieth
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
    = yield
    %p
      %tt= Time.now

@@ index

%pre= @output

