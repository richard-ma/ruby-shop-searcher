#!/usr/bin/env ruby

require "open-uri"
require "rubygems"
require "hpricot"
require "uri"
require "logger"

log_file = './runtime.log'
$delay_min, $delay_max = [10, 30]
$retry_max = 5

$log = Logger.new(log_file)
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
    cookie = nil

    [
        keyword,
        want_records,
        start_record,
        records_per_page,
        request_generator,
        parser,
        cookie,
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
    gftoken = [
        '44177aba627677a9ae2229e4',
        '7da2af024834ef4ffc2913de',
        'ec41a49182cd09c89ad26ed6',
        '7b0ce4cea59a5b2e25885432',
        'e8217d6d5e5867ee4c111822',
        '86abfa447f6f5bba838a352e',
        'd26fd59e7af81c5bd69b4a26',
        'bc719e0b7ae601e294f93c78',
        '07204593c2161adbb8fab438',
        '2c750a126213e253c0e3d870',
    ]
    cookie = "AJSTAT_ok_pages=1; AJSTAT_ok_times=1; _GFTOKEN=#{gftoken[rand(0..gftoken.length-1)]}"

    [
        keyword,
        want_records,
        start_record,
        records_per_page,
        request_generator,
        parser,
        cookie,
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
    keyword, want_records, start_record, records_per_page, request_generator, parser, cookie = resources

    records = Array.new

    retry_time = 0
    last_records_length = records.length
    while records.length < want_records and retry_time < $retry_max do
        sleep_time = rand($delay_min..$delay_max)
        url = request_generator.call(keyword, start_record, records_per_page)
        # log info
        $log.info("[#{records.length}/#{want_records}] [#{retry_time}/#{$retry_max}] [next:#{Time.now + sleep_time}] [#{keyword}] [#{url}]")

        html = open(url, {
                "User-Agent" => "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:36.0) Gecko/20100101 Firefox/36.0",
                "Cookie" => cookie
            }) { |f| f.read }
        current_records = parser.call(html)
        records = records | current_records.uniq # remove same elements

        start_record = start_record + records_per_page

        if last_records_length == records.length
            retry_time = retry_time + 1
        else
            retry_time = 0
        end
        last_records_length = records.length

        # random delay
        sleep(sleep_time)
    end

    records[0, want_records]
end

def main
    keywords_file = './keywords'
    result_dir = './sites'

    # Use gfsoso
    read_keywords_from(keywords_file).each do |keyword|
        File.open(result_dir + '/' + keyword + '.sites', 'w') do |file|
            search(gfsoso(keyword, want_records: 200)).map do |record|
                file.puts record
            end
        end
    end
end

main

#search bing 'hello'
