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

# Search tools
# Bing
def bing keyword, start_record = 1, parser = method(:bing_parser)
    ["http://global.bing.com/search?q=#{keyword}&first=#{start_record}", parser]
end

def bing_parser html
    p 'bing_parser'
end

# Baidu
def baidu keyword, start_record = 1, parser = method(:baidu_parser)
    start_record = start_record / 10
    ["http://www.baidu.com/s?wd=#{keyword}&pn=#{start_record}", parser]
end

def baidu_parser html
    p 'baidu_parser'
end

# Search bot engine
def search obj
    url, parser = obj

    html = nil
    #begin
        open url do |f|
            html = f.read
            parser.call html
        end
    #rescue StandardError, Timeout::Error, SystemCallError, Errno::ECONNREFUSED
        #p $!
    #else
        #p url
    #end

    html
end

search bing 'hello'
search baidu 'hello'
