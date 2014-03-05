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
    puts "station_list #{url}"
    doc = Nokogiri::HTML(open(url))                                                                            
                                                                                                               
    station_array = []                                                                                         
    # there are 2 tables with ID of timeTable, so re-parse 1st table and work on it for stations               
    Nokogiri::HTML(doc.search("#timeTable")[0].to_s).search("tr a").each_with_index do |element, index|        
      next if element.content.empty?                                                                           
      station_array << element.content                                                                         
    end                                                                                                        
                                                                                                               
    station_array
  end

  def self.station_data
    [ { name:"Newark",                        lat:39.670278, long:-75.753056},
      { name:"Churchman's Crossing",          lat:39.6940,   long:-75.6724},
      { name:"Wilmington",                    lat:39.736667, long:-75.551667},
      { name:"Claymont",                      lat:39.7976,   long:-75.4521},
      { name:"Marcus Hook",                   lat:39.8215,   long:-75.4197},
      { name:"Highland Avenue",               lat:39.8337,   long:-75.3929},
      { name:"Chester Transportation Center", lat:39.84932,  long:-75.35988},
      { name:"Eddystone",                     lat:39.8573,   long:-75.3416},
      { name:"Crum Lynne",                    lat:39.8719,   long:-75.3311},
      { name:"Ridley Park",                   lat:39.880523, long:-75.322105},
      { name:"Prospect Park",                 lat:39.888114, long:-75.309434},
      { name:"Norwood",                       lat:39.891360, long:-75.302221},
      { name:"Glenolden",                     lat:39.896362, long:-75.289854},
      { name:"Folcroft",                      lat:39.900667, long:-75.279543},
      { name:"Sharon Hill",                   lat:39.904255, long:-75.270971},
      { name:"Curtis Park",                   lat:39.908083, long:-75.265008},
      { name:"Darby",                         lat:39.912962, long:-75.254588},
      { name:"University City",               lat:39.94784,  long:-75.19034},
      { name:"30th Street Station",           lat:39.956924, long:-75.182576},
      { name:"Suburban Station",              lat:39.954167, long:-75.167},
      { name:"Market East",                   lat:39.952076, long:-75.156612},
      { name:"Temple University",             lat:39.9816,   long:-75.1495} ]
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

  def relative_time(start_time_str)                                                                            
    start_time = Time.parse(start_time_str)
    diff_seconds = start_time - Time.now 

    puts
    puts "start_time_str: #{start_time_str}"
    puts "start_time: #{start_time}"
    puts "time.now: #{Time.now}"
    puts "diff_mins: #{diff_seconds/60}"

    case diff_seconds
      when 0 .. 59                                                                                         
        "#{diff_seconds} seconds from now"                                                            
      when 60 .. (3600-1)                                                                                  
        "#{diff_seconds/60} minutes from now"                                                         
      when 3600 .. (3600*24-1)                                                                             
        "#{diff_seconds/3600} hours from now"                                                         
      when (3600*24) .. (3600*24*30)                                                                       
        "#{diff_seconds/(3600*24)} days from now"                                                     
      else                                                                                                 
        start_time.strftime("%m/%d/%Y")                                                               
    end                                                                                                    
  end                   

  def schedule_data
    next_arrival = nil
    # move this out, so if time out, no need  
    url = "http://www3.septa.org/hackathon/NextToArrive/#{@origin.name}/#{@destination.name}/20"
    puts "next_to_arrive #{url}"
    response = JSON.parse open(URI::encode(url)).read
    next_arrival = Hash.new("")
    response.each do |train_rec|
      next_arrival[train_rec['orig_train']] = train_rec['orig_delay']
    end

    # can cache this info
    direction_code = direction == :northbound ? 1 : 0
    origin_index = stations(direction).index(@origin.name) + 1
    destination_index = stations(direction).index(@destination.name) + 1
    train_numbers = origin_times = destination_times = nil 

    url = "http://www.septa.org/schedules/rail/w/#{ROUTE_CODE}_#{direction_code}.html"
    puts "schedule_data #{url}"
    doc = Nokogiri::HTML(open(url))

    # there are 2 tables with ID of timeTable, so re-parse 2nd table and work on those rows
    Nokogiri::HTML(doc.search("#timeTable")[1].to_s).search("tr").each_with_index do |element, index|
      train_numbers = element.content.split if index == 0               # first row is train #'s
      origin_times = element.content.split if index == origin_index           # row of times for origin
      destination_times = element.content.split if index == destination_index # row of times for destination
    end 

    # traverse each column, ie train number
    data_array = []
    train_numbers.each_with_index do |train_number, index|
      # skip if no stop time at either origin or destination
      next if origin_times[index] !~ /:/ or destination_times[index] !~ /:/  
      hash = {}
      hash[:train_number] = train_number
      hash[:time_before] = time_offset(origin_times[index], -@origin.time_before)
      hash[:time_before_relative] = relative_time(hash[:time_before])
      hash[:time_origin] = origin_times[index]
      hash[:time_destination] = destination_times[index]
      hash[:time_after] = time_offset(destination_times[index], +@destination.time_after)
      hash[:next_arrival] = next_arrival[train_number] if next_arrival
      data_array << hash
    end 
    
    data_array
  end
  
  def schedule_json
  end

  def schedule_text
    output = ""
    schedule_data.each_with_index do |hash, index|
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
  ap r2.schedule_data

  r2.flip!
  puts "#{thirtieth.name} >> #{claymont.name}\n\n"
  puts r2.schedule_text
  ap r2.schedule_data

  puts r2.station_list.reverse.map{|s| "+ #{s}"}
  ap r2.station_list

  ap SeptaR2.station_data
end
