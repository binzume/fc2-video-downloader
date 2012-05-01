# -*- encoding: utf-8 -*-
require 'digest/md5'
require 'kconv'
require_relative 'httpclient'

module FC2
  class Video
    attr_accessor :url, :upid, :title, :file_url, :ext
    def initialize url
      @url = url
      @upid = (url.match(/\/content.*\/([^\/]+)/)||[])[1]
      @pay = false
    end

    def loadinfo session=nil
      client = HTTPClient.new({:agent_name=>'Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/536.9'})
      if session
        client.cookies["video.fc2.com"] = session["ssid"]
        @pay = session["pay"]
      end

      r = client.get(@url)

      gkarray = []
      r.body.scan(/<script[^>]*>(.*?)<\/script>/mi) {|js|
        if js[0]=~/getKey/
          js[0].scan(/\w+\s+\w+\((\d+),([^\)]+)\)/im){|kf|
            gkarray[kf[0].to_i] = kf[1].gsub(/[\\']/,"")
          }
        end
      }

      @title = ""
      if r.body =~ /<meta property="og:title" content="([^"]+)">/
        @title = $1.gsub(/["\&<>\|]/,"_").toutf8
      end

      @mimi = Digest::MD5.new.update(@upid + '_gGddgPfeaf_gzyr') . to_s;
      @gk = gkarray.join

      ginfourl = "http://video.fc2.com/ginfo.php?upid="+@upid
      if @pay
        ginfourl = "http://video.fc2.com/ginfo_payment.php?upid="+@upid
      end
      ginfourl += "&v="+@upid + "&mimi=" + @mimi + "&gk=" + @gk

      pr = client.get(ginfourl)
      params = Hash[ pr.body.split("&").map{|kv| kv.split("=",2)} ]

      @file_url = ""+params["filepath"] + "?mid=" + params["mid"]
      @ext = (params["filepath"].match(/\.\w+$/)||[""])[0]
      @client = client
    end

    def download_request &block
        @client.request_get(@file_url, nil, &block)
    end

    def download &block
        return @client.get(@file_url, nil, &block)
    end
  end

  def self.login account
    puts "unimplemented."
  end

  def self.video url,session=nil
    video = Video.new(url)
    video.loadinfo(session)
    return video
  end
end

