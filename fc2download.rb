#!/usr/bin/ruby -Ku
# -*- encoding: utf-8 -*-
require 'yaml'
require_relative 'fc2'

url = ARGV[0]
unless url
  puts "usage fc2.rb [URL]"
  exit
end


account_file = File.dirname(__FILE__) + '/account.yaml'
session_file = File.dirname(__FILE__) + '/session.yaml'

if File.exists?(session_file)
  session = FC2::Session.new(YAML.load_file(session_file))
else
  session = FC2::Session.new
end

if File.exists?(account_file)
  account = YAML.load_file(account_file)
  session.account = account
  # session.login(account)
end

# get video info
v = FC2.video(ARGV[0], session)
#puts v.file_url
#puts title
#puts video_url

# TODO: save session
#open(session_file, "w") {|f|
# f.write(YAML.dump(session.hash))
#}

# Download video
begin
  fname = v.upid+"_" + v.title.gsub(/[\?"\&<>\|\/\\\*\{\}]/,"_")
  puts "file: " + fname + v.ext
  tmp = fname+"_part"+v.ext
  f = open(tmp,"wb")

  v.download_request{|res|
    size = res['content-length'].to_i
    purs "status:" + res.code
    puts "size: "+size.to_s
    len = 0
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

