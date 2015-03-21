#!/usr/bin/env ruby

require "open-uri"

keywords_file = './keywords'
result_dir = '/tmp/rubyShopSearcher'

# Reading keywords
def read_keywords_from keywords_file
    keywords = Array.new

    open keywords_file do |f|
        f.each_line do |keyword|
            keywords << keyword
        end
    end

    keywords
end

# Bing
def bing keyword, start_record = 1
    "http://global.bing.com/search?q=#{keyword}&first=#{start_record}"
end

# Baidu
def baidu keyword, start_record = 1
    start_record = start_record / 10
    "http://www.baidu.com/s?wd=#{keyword}&pn=#{start_record}"
end

def search url
    html = nil
    begin
        open url do |f|
            html = f.read
        end
    rescue StandardError, Timeout::Error, SystemCallError, Errno::ECONNREFUSED
        p $!
    else
        p url
    end

    html
end

p search baidu 'hello'
