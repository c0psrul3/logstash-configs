Perform Geo location on the source IP address and destination IP address:

You must download the Maxmind GeoIP database and place the file in /opt/logstash.

#Geolocate logs that have SourceAddress and if that SourceAddress is a non-RFC1918 address or APIPA address
if [SourceAddress] and [SourceAddress] !~ "(^127\.0\.0\.1)|(^10\.)|(^172\.1[6-9]\.)|(^172\.2[0-9]\.)|(^172\.3[0-1]\.)|(^192\.168\.)|(^169\.254\.)" {
    geoip {
         database => "/opt/logstash/GeoLiteCity.dat"
         source => "SourceAddress"
         target => "SourceGeo"
    }
    #Delete 0,0 in SourceGeo.location if equal to 0,0
    if ([SourceGeo.location] and [SourceGeo.location] =~ "0,0") {
      mutate {
        replace => [ "SourceGeo.location", "" ]
      }
    }
  }

#Geolocate logs that have DestinationAddress and if that DestinationAddress is a non-RFC1918 address or APIPA address
if [DestinationAddress] and [DestinationAddress] !~ "(^127\.0\.0\.1)|(^10\.)|(^172\.1[6-9]\.)|(^172\.2[0-9]\.)|(^172\.3[0-1]\.)|(^192\.168\.)|(^169\.254\.)" {
    geoip {
         database => "/opt/logstash/GeoLiteCity.dat"
         source => "DestinationAddress"
         target => "DestinationGeo"
    }
    #Delete 0,0 in DestinationGeo.location if equal to 0,0
    if ([DestinationGeo.location] and [DestinationGeo.location] =~ "0,0") {
      mutate {
        replace => [ "DestinationAddress.location", "" ]
      }
    }
  }

