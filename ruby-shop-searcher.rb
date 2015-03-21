#!/usr/bin/env ruby

require "open-uri"
require "rubygems"
require "hpricot"
require "uri"
require "logger"

keywords_file = './keywords'
result_dir = './sites'

$log = Logger.new(STDERR)
$log.level = Logger::DEBUG

# Reading keywords
def read_keywords_from keywords_file
    keywords = nil

    open keywords_file do |f|
        keywords = f.each_line.map do |keyword|
            keyword.chomp
        end
    end

    keywords
end

# Search tools
# Bing
def bing (keyword, start_record: 1, parser: method(:bing_default_parser))
    ["http://global.bing.com/search?q=#{keyword}+language%3Aen&first=#{start_record}", parser]
end

def bing_default_parser (html)
    html.search("#b_results/li/h2/a").each do |result|
        $log.debug(result.attributes['href'])
    end
end

# Baidu
def baidu (keyword, want_records: 10, start_record: 0, records_per_page: 20, request_generator: method(:baidu_request_generator), parser: method(:baidu_default_parser))
    [
        keyword,
        want_records,
        start_record,
        records_per_page,
        request_generator,
        parser,
    ]
end

def baidu_request_generator (keyword, start_record, records_per_page)
    URI.escape("http://www.baidu.com/s?wd=#{keyword}&pn=#{start_record}&rn=#{records_per_page}") # URI escaping
end

def baidu_default_parser (html)
    html = Hpricot::new(html) # Use hpricot parsing HTML
    results = html.search("div.result/h3/a").map do |result|
        baidu_short_link = result.attributes['href']
        begin
            site = open(baidu_short_link, {
                "User-Agent" => "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:36.0) Gecko/20100101 Firefox/36.0",
            })
            result = site.base_uri.to_s
        rescue => e
            # log error
            $log.error(e)
            result = baidu_short_link
            next
        ensure
            # log ever result in DEBUG mode
            $log.debug(result)
        end
    end
end

# GFsoso (Google)
def gfsoso (keyword, want_records: 10, start_record: 0, records_per_page: 10, request_generator: method(:gfsoso_request_generator), parser: method(:gfsoso_default_parser))
    records_per_page = 10 # cann't change records per page

    [
        keyword,
        want_records,
        start_record,
        records_per_page,
        request_generator,
        parser,
    ]
end

def gfsoso_request_generator (keyword, start_record, records_per_page)
    URI.escape("http://www.gfsoso.com/?q=#{keyword}&filter=null&src=google&nfpr=0&lr=en&pn=#{start_record}") # URI escaping
end

def gfsoso_default_parser (html)
    links = html.scan(/\<span class=\\"st\\" style=\\"word\-break:break-all;font-family:Arial;\\"\>\s\s\s\s(\S*)\s\s\s\<\\\/span\>/)

    records = Array.new
    links.each do |link|
        records << link.first.gsub('\\', '').gsub(/\/.*$/, '').gsub(/^/, 'http://')
    end

    records
end

# Search bot engine
def search resources
    keyword, want_records, start_record, records_per_page, request_generator, parser = resources

    records = Array.new

    while records.length < want_records do
        # log records length in DEBUG mode
        $log.debug(records.length)
        url = request_generator.call(keyword, start_record, records_per_page)
        # log request url in DEBUG mode
        $log.debug(url)

        html = open(url, {
                "User-Agent" => "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:36.0) Gecko/20100101 Firefox/36.0",
                "Cookie" =>  "_GFTOKEN=e6aef733c8b5ed6b9df57480",
            }) { |f| f.read }
        current_records = parser.call(html)
        records = records | current_records.uniq # remove same elements

        start_record = start_record + records_per_page
    end

    records[0, want_records]
end

#search bing 'hello'
read_keywords_from(keywords_file).each do |keyword|
    File.open(result_dir + '/' + keyword + '.sites', 'w') do |file|
        search(gfsoso(keyword, want_records: 10000)).map do |record|
            file.puts record
        end
    end
end
