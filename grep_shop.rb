#!/usr/bin/env ruby

require "open-uri"

def usage
    puts "Please input a checked sites file name"
    puts "File name must ended with .sites.checked"
    exit 1
end

def check_filename(file_name)
    /.sites.checked$/ =~ file_name
end

def load_dropped_sites
    dropped_sites_file = 'dropped_sites'

    f = open(dropped_sites_file)
    f.each_line.map do |site|
        site.chomp
    end
end

def write_dropped_sites(dropped_sites_delta)
    f = open(dropped_sites_file, 'a')
    dropped_sites_delta.each do |site|
        f.puts site
    end
end

def log_dropped_site(site)
    puts "logging dropped sites: #{site}"
end

def main
    # check command line arguments
    usage if not ARGV.length == 1

    checked_sites_file = ARGV[0] # ruby command line argument start with 0!!!
    usage if not check_filename(checked_sites_file)
    # show file name OK DEBUG mode
    p 'file name check OK'

    dropped_sites = load_dropped_sites
    dropped_sites_delta = []
    accepted_sites = []
    # show dropped sites loaded DEBUG mode
    p "dropped_sites loaded [#{dropped_sites.length}]"

    # open a checked sites file
    open(checked_sites_file) do |file|
        file.each_line do |site|
            site = site.chomp

            if dropped_sites.include?(site)
                log_dropped_site(site)
            else
                accepted_flg = false # site can be accepted? init to false
                # check site accessable
                begin
                    html = open(site) { |f| f.read }
                    # check rules
                    accepted_flg = true if /cart|basket|ecshop/ =~ html
                rescue => e
                    puts "#{site} Error: #{e}"
                    # log open error
                ensure
                    # add to dropped sites
                    if accepted_flg == false
                        dropped_sites << site 
                        dropped_sites_delta << site
                    end
                    if accepted_flg == true
                        accepted_sites << site
                        # logging accept site
                        p "Accepted site: #{site}"
                    end
                end
            end
        end
    end

    # update dropped site file
    write_dropped_sites(dropped_sites_delta) if not dropped_sites_delta.empty?
end

# run!!!
main
