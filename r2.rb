#!/usr/bin/env ruby

require 'net/http'
require 'open-uri'
require 'nokogiri'
require 'json'
require 'time'

Station = Struct.new(:code, :name, :time_before, :time_after)

class SeptaR2

  ROUTE_CODE = "WIL"

  attr_reader :station_list

  def initialize(origin, destination)
    @station_list = get_stations
    @origin = origin
    @destination = destination
  end

  def self.station_list
    # northbound order
    url = "http://www.septa.org/schedules/rail/w/#{ROUTE_CODE}_1.html"
    doc = Nokogiri::HTML(open(url))                                                                            
                                                                                                               
    station_array = []                                                                                         
    # there are 2 tables with ID of timeTable, so re-parse 1st table and work on it for stations               
    Nokogiri::HTML(doc.search("#timeTable")[0].to_s).search("tr a").each_with_index do |element, index|        
      next if element.content.empty?                                                                           
      station_array << element.content                                                                         
    end                                                                                                        
                                                                                                               
    station_array
  end

  def get_stations                                                                                             
    # northbound order
    url = "http://www.septa.org/schedules/rail/w/#{ROUTE_CODE}_1.html"
    doc = Nokogiri::HTML(open(url))                                                                            
                                                                                                               
    station_array = []                                                                                         
    # there are 2 tables with ID of timeTable, so re-parse 1st table and work on it for stations               
    Nokogiri::HTML(doc.search("#timeTable")[0].to_s).search("tr a").each_with_index do |element, index|        
      next if element.content.empty?                                                                           
      station_array << element.content                                                                         
    end                                                                                                        
                                                                                                               
    station_array                                                                                              
  end       

  def direction
    @station_list.index(@origin.name) < @station_list.index(@destination.name) ? :northbound : :southbound
  end

  def stations(direction_sym)
    direction_sym == :northbound ? @station_list : @station_list.reverse
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
      output += "%7s" % time_offset(line['orig_departure_time'], -@origin.time_before)
      output += " "
      output += "[#{line['orig_departure_time']} #{"%4s" % line['orig_train']}]"
      output += " ~> "
      output += line['orig_arrival_time']
      output += " "
      output += line['orig_delay']
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
      output += "%7s" % time_offset(origin_times[index], -@origin.time_before)
      output += " "
      output += "[#{"%7s" % origin_times[index]} #{"%4s" % train_number}]"
      output += " ~> "
      output += "%7s" % destination_times[index]
      output += " "
      output += "%7s" % time_offset(destination_times[index], +@destination.time_after)
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

  puts r2.station_list.reverse.map{|s| "+ #{s}"}
end
