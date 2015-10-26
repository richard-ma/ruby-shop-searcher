#!/usr/bin/env ruby

require 'open-uri'
require "uri"
require 'net/http'
require "logger"

log_file = './runtime.log'
$log = Logger.new(log_file)
$log.level = Logger::DEBUG

def main
    domain = "www.justlowprices.co.uk"
    url = "http://#{domain}/deals/fasion-and-accessories.html?fp=1&st=latest"
    html = open(url) { |f| f.read }
    page_info = html.scan(/<span>([0-9\/]*)<\/span>/).first.first
    current_page, total_page = page_info.split('/')
    current_page = current_page.to_i
    total_page = total_page.to_i

    result = Array.new
    while current_page <= total_page
        $log.info("#{current_page}/#{total_page}")
        url = "http://#{domain}/deals/fasion-and-accessories.html?fp=#{current_page}&st=latest"
        html = open(url) { |f| f.read }
        links = html.scan(/<a target='\_blank' href="([^"]*)" class="link-btn"/)

        links.each do |link|
            real_url = URI.parse("http://#{domain}#{link[0]}")
            res = Net::HTTP.start(real_url.host, real_url.port) { |http|
                http.get(real_url.request_uri)
            }
            location = res['location'].scan(/^(http\:\/\/[^\/]*\/)/)
            $log.info("#{location}")
            result << location
        end
    
        current_page = current_page + 1
    end

    result.each do |record|
        puts record
    end
end

# run!!!
main
