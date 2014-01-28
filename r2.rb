#!/usr/bin/env ruby

require 'net/http'
require 'open-uri'
require 'nokogiri'
require 'json'
require 'time'
require 'awesome_print'

Station = Struct.new(:code, :name, :time_before, :time_after)

class SeptaR2

  ROUTE_CODE = "WIL"

  attr_reader :station_list

  def initialize(origin, destination)
    @station_list = SeptaR2.station_list
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
    (Time.parse(time_str)+(minutes*60)).strftime("%I:%M%P")
  end

  def schedule_data
    url = "http://www3.septa.org/hackathon/NextToArrive/#{@origin.name}/#{@destination.name}/20"
    response = JSON.parse open(URI::encode(url)).read
    next_arrival = Hash.new("")
    response.each do |train_rec|
      next_arrival[train_rec['orig_train']] = train_rec['orig_delay']
    end

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
    array = []
    train_numbers.each_with_index do |train_number, index|
      # skip if no stop time at either origin or destination
      next if origin_times[index] !~ /:/ or destination_times[index] !~ /:/  
      hash = {}
      hash[:train_number] = train_number
      hash[:time_before] = time_offset(origin_times[index], -@origin.time_before)
      hash[:time_origin] = origin_times[index]
      hash[:time_destination] = destination_times[index]
      hash[:time_after] = time_offset(destination_times[index], +@destination.time_after)
      hash[:next_arrival] = next_arrival[train_number]
      array << hash
    end 
    
    ap array
    array

    # # traverse each column, ie train number
    # output = ""
    # array.each_with_index do |hash, index|
    #   # skip if no stop time at either origin or destination
    #   output += "%7s" % hash[:time_before]
    #   output += " "
    #   output += "["
    #   output += "%7s" % hash[:time_origin]
    #   output += " "
    #   output += "(%4s)" % hash[:train_number]
    #   output += " "
    #   output += "%7s" % hash[:time_destination]
    #   output += "]"
    #   output += " "
    #   output += "%7s" % hash[:time_after]
    #   output += " "
    #   output += hash[:next_arrival]
    #   output += "\n"
    # end 
    # output += "\n"

    # # traverse each column, ie train number
    # output = ""
    # train_numbers.each_with_index do |train_number, index|
    #   # skip if no stop time at either origin or destination
    #   next if origin_times[index] !~ /:/ or destination_times[index] !~ /:/  
    #   output += "%7s" % time_offset(origin_times[index], -@origin.time_before)
    #   output += " "
    #   output += "["
    #   output += "%7s" % origin_times[index]
    #   output += " "
    #   output += "(%4s)" % train_number
    #   output += " "
    #   output += "%7s" % destination_times[index]
    #   output += "]"
    #   output += " "
    #   output += "%7s" % time_offset(destination_times[index], +@destination.time_after)
    #   output += " "
    #   output += next_arrival[train_number]
    #   output += "\n"
    # end 
    # output += "\n"
  end

  def schedule_text
    array = schedule_data
    # traverse each column, ie train number
    output = ""
    array.each_with_index do |hash, index|
      # skip if no stop time at either origin or destination
      output += "%7s" % hash[:time_before]
      output += " "
      output += "["
      output += "%7s" % hash[:time_origin]
      output += " "
      output += "(%4s)" % hash[:train_number]
      output += " "
      output += "%7s" % hash[:time_destination]
      output += "]"
      output += " "
      output += "%7s" % hash[:time_after]
      output += " "
      output += hash[:next_arrival]
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
  puts r2.schedule_text
  r2.flip!
  puts "#{thirtieth.name} >> #{claymont.name}\n\n"
  puts r2.schedule_text

  puts r2.station_list.reverse.map{|s| "+ #{s}"}

end
