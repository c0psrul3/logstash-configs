#!/bin/sh
curl -XPUT http://10.0.0.112:9200/_template/logstash_per_index -d '
{
    "template" : "logstash*",
    "mappings" : {
      "cisco-fw" : {
         "properties": {
            "@timestamp":{"type":"date","format":"dateOptionalTime"},
            "@version":{"type":"string", "index" : "not_analyzed"},
	    "action":{"type":"string"},
	    "bytes":{"type":"long"},
	    "cisco_message":{"type":"string"},
	    "ciscotag":{"type":"string", "index" : "not_analyzed"},
	    "connection_count":{"type":"long"},
            "connection_count_max":{"type":"long"},
	    "connection_id":{"type":"string"},
            "direction":{"type":"string"},
            "dst_interface":{"type":"string"},
	    "dst_ip":{"type":"string"},
            "dst_mapped_ip":{"type":"ip"},
	    "dst_mapped_port":{"type":"long"},
            "dst_port":{"type":"long"},
            "duration":{"type":"string"},
	    "err_dst_interface":{"type":"string"},
	    "err_dst_ip":{"type":"ip"},
	    "err_icmp_code":{"type":"string"},
	    "err_icmp_type":{"type":"string"},
	    "err_protocol":{"type":"string"},
            "err_src_interface":{"type":"string"},
            "err_src_ip":{"type":"ip"},
            "geoip":{
               "properties":{
                  "area_code":{"type":"long"},
                  "asn":{"type":"string", "index":"not_analyzed"},
                  "city_name":{"type":"string", "index":"not_analyzed"},
                  "continent_code":{"type":"string"},
                  "country_code2":{"type":"string"},
                  "country_code3":{"type":"string"},
                  "country_name":{"type":"string", "index":"not_analyzed"},
                  "dma_code":{"type":"long"},
                  "ip":{"type":"ip"},
                  "latitude":{"type":"double"},
                  "location":{"type":"geo_point"},
                  "longitude":{"type":"double"},
                  "number":{"type":"string"},
                  "postal_code":{"type":"string"},
                  "real_region_name":{"type":"string", "index":"not_analyzed"},
                  "region_name":{"type":"string", "index":"not_analyzed"},
                  "timezone":{"type":"string"}
               }
            },
            "group":{"type":"string"},
 	    "hashcode1": {"type": "string"}, 
 	    "hashcode2": {"type": "string"}, 
            "host":{"type":"string"},
            "icmp_code":{"type":"string"},
            "icmp_code_xlated":{"type":"string"},
            "icmp_seq_num":{"type":"string"},
            "icmp_type":{"type":"string"},
            "interface":{"type":"string"},
            "is_local_natted":{"type":"string"},
            "is_remote_natted":{"type":"string"},
            "message":{"type":"string"},
            "orig_dst_ip":{"type":"ip"},
            "orig_dst_port":{"type":"long"},
            "orig_protocol":{"type":"string"},
            "orig_src_ip":{"type":"ip"},
            "orig_src_port":{"type":"long"},
            "policy_id":{"type":"string"},
            "protocol":{"type":"string"},
            "reason":{"type":"string"},
            "seq_num":{"type":"long"},
            "spi":{"type":"string"},
            "src_interface":{"type":"string"},
            "src_ip":{"type":"ip"},
            "src_mapped_ip":{"type":"ip"},
            "src_mapped_port":{"type":"long"},
            "src_port":{"type":"long"},
            "src_xlated_interface":{"type":"string"},
            "src_xlated_ip":{"type":"ip"},
            "syslog_facility":{"type":"string"},
            "syslog_facility_code":{"type":"long"},
            "syslog_pri":{"type":"string"},
            "syslog_severity":{"type":"string"},
            "syslog_severity_code":{"type":"long"},
            "tags":{"type":"string"},
            "tcp_flags":{"type":"string"},
            "timestamp":{"type":"string"},
            "tunnel_type":{"type":"string"},
            "type":{"type":"string"},
            "user":{"type":"string"},
            "xlate_type":{"type":"string"}
      }
    }
  }
}'
