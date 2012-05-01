#!/usr/bin/ruby -Ku
# -*- encoding: utf-8 -*-
require 'yaml'
require_relative 'fc2'

url = ARGV[0]
unless url
  puts "usage fc2.rb [URL]"
  exit
end


# TODO: login
conf_file = File.dirname(__FILE__) + '/session.yaml'
session = YAML.load_file(conf_file)
#account = YAML.load_file(conf_file)
#session = FC2.login(account)
#open(conf_file, "w") {|f|
# f.write(YAML.dump(session))
#}

# get video info
v = FC2.video(ARGV[0], session)
#puts v.file_url
#puts title
#puts video_url

# Download video
begin
  fname = v.upid+"_" + v.title.gsub(/[\?"\&<>\|]/,"_")
  puts fname + v.ext
  tmp = fname+"_part"+v.ext
  f = open(tmp,"wb")

  v.download_request{|res|
    len = 0
    size = res['content-length'].to_i
    p res.code
    puts "size: "+size.to_s
    res.read_body{|d|
      len += d.length
      print "\b\b\b\b\b\b\b\b\b\b\b\b\b"+ (len/(1024)).to_s + "KB"
      if size && size>0
        print " " + (len*100/size).to_i.to_s + "%"
      end
      STDOUT.flush
      f.write(d)
    }
  }
  f.close

  File.rename(tmp, fname+".mp4")
rescue Interrupt
  puts "Abort."
end

