# -*- encoding: utf-8 -*-
require 'digest/md5'
require 'kconv'
require_relative 'httpclient'

module FC2
  class Session
    attr_accessor :client, :ssid, :pay, :account
    def initialize hash = nil
      @client = HTTPClient.new({:agent_name=>'Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/536.9'})
      @ssid = hash && hash["ssid"] || {}
      @pay = hash && hash["pay"]
    end

    def login account = nil
      if account
        @account = account
      end
      client = @client
      client.cookies["secure.id.fc2.com"] = @ssid
      client.cookies["id.fc2.com"] = @ssid
      client.cookies["video.fc2.com"] = @ssid

      res = client.post("https://secure.id.fc2.com/index.php?mode=login&switch_language=ja", @account)
      unless res.body.index("http://id.fc2.com/?login=done")
        return false
      end
      res = client.get("http://id.fc2.com/?login=done")
      res = client.get("https://secure.id.fc2.com/?done=video&switch_language=ja")
      if res.body =~/(http:\/\/video.fc2.com\/mem_login.php[^"\s]+)/mi
        puts $1
        res = client.get($1)
      end

      if res['location'].index("/logoff.php")
        # http://video.fc2.com/logoff.php
        p res['location']
        return false
      end

      return true
    end
  end

  class Video
    attr_accessor :url, :upid, :title, :file_url, :ext
    def initialize url
      @url = url
      @upid = (url.match(/\/content.*\/([^\/]+)/)||[])[1]
      @pay = false
    end

    def loadinfo session=nil
      @session = session
      client = session.client
      if session
        client.cookies["video.fc2.com"] = session.ssid
        @pay = session.pay
      end

      r = client.get(@url)

      if session.account && r.body.index("<body onload=\"loadLoginInfo('0')\"")
        session.login
        r = client.get(@url)
      end

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
    end

    def download_request &block
        @session.client.request_get(@file_url, nil, &block)
    end

    def download &block
        return @session.client.get(@file_url, nil, &block)
    end
  end

  def self.video url,session=nil
    video = Video.new(url)
    video.loadinfo(session)
    return video
  end
end

