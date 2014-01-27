#!/usr/bin/env ruby

require 'net/http'
require 'open-uri'
require 'nokogiri'
require 'json'
require 'time'

Station = Struct.new(:code, :name, :time_before, :time_after)

class SeptaR2

  ROUTE_CODE = "WIL"

  # northbound order
  STATIONS = [ "Newark", "Churchmans Crossing", "Wilmington", "Claymont", "Marcus Hook", "Highland Avenue", 
               "Chester", "Eddystone", "Crum Lynne", "Ridley Park", "Prospect Park", "Norwood", 
               "Glenolden", "Folcroft", "Sharon Hill", "Curtis Park", "Darby", "University City", 
               "30th Street Station", "Suburban Station", "Market East Station", "Temple University"]

  def initialize(origin, destination)
    @origin = origin
    @destination = destination
  end

  def direction
    STATIONS.index(@origin.name) < STATIONS.index(@destination.name) ? :northbound : :southbound
  end

  def stations(direction_sym)
    direction_sym == :northbound ? STATIONS : STATIONS.reverse
  end

  def flip!
    @origin, @destination = @destination, @origin
  end

  def time_offset(time_str, minutes)
    (Time.parse(time_str)+(minutes*60)).strftime("%l:%M%P")
  end

  def next
    url = "http://www3.septa.org/hackathon/NextToArrive/#{@origin.name}/#{@destination.name}/20"
    response = JSON.parse open(URI::encode(url)).read
  
    output = ""
    response.each do |line|
      output += "#{line['orig_departure_time']}"
      output += " ~> "
      output += "#{line['orig_arrival_time']}"
      output += " "
      output += "#{line['orig_delay']}"
      output += " "
      output += "#{"%4s" % line['orig_train']}"
      output += "\n"
    end
    output += "\n"
  end
 
  def schedule
    direction_code = direction == :northbound ? 1 : 0
    origin_index = stations(direction).index(@origin.name) + 1
    destination_index = stations(direction).index(@destination.name) + 1
    train_numbers = origin_times = destination_times = nil 

    url = "http://www.septa.org/schedules/rail/w/#{ROUTE_CODE}_#{direction_code}.html"
    doc = Nokogiri::HTML(open(url))

    # there are 2 tables with ID of timeTable, so re-parse 2nd table and work on those rows
    Nokogiri::HTML(doc.search("#timeTable")[1].to_s).search("tr").each_with_index do |element, index|
      train_numbers = element.content.split if index == 0               # first row is train #'s
      origin_times = element.content.split if index == origin_index           # row of times for origin
      destination_times = element.content.split if index == destination_index # row of times for destination
    end 
    
    # traverse each column, ie train number
    output = ""
    train_numbers.each_with_index do |train_number, index|
      # skip if no stop time at either origin or destination
      next if origin_times[index] !~ /:/ or destination_times[index] !~ /:/  
      output += "#{"%7s" % time_offset(origin_times[index], -@origin.time_before)}"
      output += " "
      output += "[#{"%7s" % origin_times[index]} #{"%4s" % train_number}]"
      output += " ~> "
      output += "#{"%7s" % destination_times[index]}"
      output += " "
      output += "#{"%7s" % time_offset(destination_times[index], +@destination.time_after)}"
      output += "\n"
    end 
    output += "\n"
  end
end

if $0 == __FILE__

  claymont = Station.new
  claymont.name = "Claymont"
  claymont.time_before = 20
  claymont.time_after = 15

  thirtieth = Station.new
  thirtieth.name = "30th Street Station"
  thirtieth.time_before = 15
  thirtieth.time_after = 10

  r2 = SeptaR2.new claymont, thirtieth
  puts "#{claymont.name} >> #{thirtieth.name}\n\n"
  puts "Next to Arrive\n\n"
  puts r2.next
  puts "Weekday Schedule\n\n"
  puts r2.schedule
  r2.flip!
  puts "#{thirtieth.name} >> #{claymont.name}\n\n"
  puts "Next to Arrive\n\n"
  puts r2.next
  puts "Weekday Schedule\n\n"
  puts r2.schedule

end
