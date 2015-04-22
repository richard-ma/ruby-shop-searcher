#!/usr/bin/env ruby

require "open-uri"

# every proxy test
IO.foreach("../proxy_list") do |proxy|
    proxy = proxy.chomp

    # start test
    ip = /\d+.\d+.\d+.\d+/.match(proxy).to_s
    port = /\d+$/.match(proxy).to_s

    begin
        html = open('http://1111.ip138.com/ic.asp', {proxy: proxy}) { |f| f.read }
        tested_ip = /\d+.\d+.\d+.\d+/.match(html).to_s

        if ip == tested_ip
            puts "[S] #{proxy} -> #{tested_ip}"
        else
            puts "[F] #{proxy} -> #{tested_ip}"
        end
    rescue => e
        puts "[E] #{e.to_s}"
    end
end
