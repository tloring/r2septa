#!/usr/bin/env ruby

require 'net/http'
require 'open-uri'
require 'nokogiri'
require 'json'

class SeptaR2

  CODES = { :claymont => "Claymont", :thirtieth => "30th Street Station" }

  def initialize(origin, destination)
    @origin = origin
    @destination = destination
  end

  def flip!
    tmp = @origin
    @origin = @destination
    @destination = tmp
  end

  def next
    output = "Next to Arrive #{CODES[@origin]} >> #{CODES[@destination]}\n\n"

    url = "http://www3.septa.org/hackathon/NextToArrive/#{CODES[@origin]}/#{CODES[@destination]}/20"
    response = JSON.parse open(URI::encode(url)).read
  
    response.each do |line|
      output += "#{line['orig_departure_time']} ~> #{line['orig_arrival_time']} #{line['orig_delay']} #{"%4s" % line['orig_train']}\n"
    end
    output += "\n"
  end

  def schedule
    output = "Weekday Schedule #{CODES[@origin]} >> #{CODES[@destination]}\n\n"

    route = "WIL"
    origin_index = 4 
    destination_index = 19
    direction_code = (@origin == :thirtieth) ? 0 : 1  # southbound=0, northbound=1
    train_numbers = origin_times = destination_times = nil 

    url = "http://www.septa.org/schedules/rail/w/#{route}_#{direction_code}.html"
    doc = Nokogiri::HTML(open(url))

    # there are 2 tables with ID of timeTable, so re-parse 2nd table and work on those rows
    Nokogiri::HTML(doc.search("#timeTable")[1].to_s).search("tr").each_with_index do |element, index|
      train_numbers = element.content.split if index == 0               # first row is train #'s
      origin_times = element.content.split if index == origin_index           # row of times for origin
      destination_times = element.content.split if index == destination_index # row of times for destination
    end 
    
    # traverse each column, ie train number
    train_numbers.each_with_index do |train_number, index|
      # skip if no stop time at either origin or destination
      next if origin_times[index] !~ /:/ or destination_times[index] !~ /:/  
      output += "#{"%7s" % origin_times[index]} ~> #{"%7s" % destination_times[index]} #{"%4s" % train_number}\n"
    end 
    output += "\n"
  end
end

if $0 == __FILE__

  r2 = SeptaR2.new :claymont, :thirtieth
  puts r2.next
  puts r2.schedule
  r2.flip!
  puts r2.next
  puts r2.schedule

end
