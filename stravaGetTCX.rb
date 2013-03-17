#!/usr/bin/env ruby

require 'rubygems'
require 'erubis'
require 'strava-api'
require 'awesome_print'
require 'ruby-debug'

rides = ARGV
strava = StravaApi::Base.new

def load_template
    tcx = Erubis::Eruby.new( File.read( File::dirname(__FILE__) + "/base.tcx.erb" ) )
end

def tcx_time( atime )
    atime.strftime("%Y-%m-%dT%H:%M:%SZ")
end

def from_strava_time( stravatime )
    Time.parse(stravatime.to_s)
end

def ride_id_from_url( url  )
    url.match(/\d+/)[-1]
end

tcx = load_template
rides.each do |ride|

    ride = ride_id_from_url( ride )
    p "Fetching data  for ride #{ride}"
    ride = strava.ride_show( ride )
    time_origin = from_strava_time( ride.start_date_local )
    ap ride
    streams = ride.streams
    trackpoints = []
    until streams.time.empty?
        trackpoints <<= {
            :time       => time_origin + streams.time.shift,
            :altitude   => streams.altitude   && streams.altitude.shift,
            :cadence    => streams.cadence    && streams.cadence.shift,
            :distance   => streams.distance   && streams.distance.shift,
            :heartrate  => streams.heartrate  && streams.heartrate.shift,
            :latlng     => streams.latlng     && streams.latlng.shift,
            :watts      => streams.watts      && streams.watts.shift,
            :watts_calc => streams.watts_calc && streams.watts_calc.shift,
        }
    end

    ap trackpoints[-1]
    render =  tcx.result( :ride=>ride, :trackpoints=>trackpoints )
    # ap render.split[8..38]

    File.open( time_origin.strftime("%Y %m %d - %H %S") + ".tcx", "w+" ) { |fo|
        fo.write( render )
    }
end
    
