#!/usr/bin/env ruby

require "open-uri"
require "rubygems"
require "hpricot"

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
def bing keyword, start_record = 1, parser = method(:bing_default_parser)
    ["http://global.bing.com/search?q=#{keyword}+language%3Aen&first=#{start_record}", parser]
end

def bing_default_parser html
    html.search("#b_results/li/h2/a").each do |result|
        p result.attributes['href']
    end
end

# Baidu
def baidu keyword, start_record = 1, parser = method(:baidu_default_parser)
    start_record = start_record / 10
    ["http://www.baidu.com/s?wd=#{keyword}&pn=#{start_record}", parser]
end

def baidu_default_parser html
    results = html.search("div.result/h3/a").map do |result|
        baidu_short_link = result.attributes['href']
        begin
            site = open(baidu_short_link, {
                "User-Agent" => "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:36.0) Gecko/20100101 Firefox/36.0",
            })
            result = site.base_uri.to_s
        rescue => e
            # TODO log error
            result = baidu_short_link
            next
        ensure
            # TODO log ever result in DEBUG mode
            #p result
        end
    end
end

# Search bot engine
def search obj
    url, parser = obj

    results = nil
    begin
        html = open(url) {|f| Hpricot(f)} # get html and use Hpricot parsing
        results = parser.call html
    rescue => e
        # nothing to do
    end

    results
end

search bing 'hello'
p search baidu 'china'
