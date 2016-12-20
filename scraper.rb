#!/bin/env ruby
# encoding: utf-8

require 'nokogiri'
require 'open-uri'
require 'pry'
require 'scraperwiki'

require 'open-uri/cached'
OpenURI::Cache.cache_path = '.cache'

def noko_for(url)
  Nokogiri::HTML(open(url).read)
end

def date_from(date)
  return if date.nil? || date.empty?
  Date.parse(date).to_s
end

def scrape_list(id, url)
  puts "Scraping #{id}"
  noko = noko_for(url)
  noko.css('#ledamots a/@href').map(&:text).each do |link|
    scrape_mp(URI.join(url, link).to_s, id)
  end
 end

def scrape_mp(url, termid)
  noko = noko_for(url)
  box = noko.css('div#news')
  named = ->(t) { box.xpath("(.//strong[contains(.,'#{t}')] | .//b[contains(.,'#{t}')])/following-sibling::text()") }
  data = { 
    id: url[/iPerson=(\d+)/, 1],
    name: box.css('h3').text.strip,
    image: box.css('img/@src').text,
    party: named.("Grupptill").first.text.gsub(/[[:space:]]+/, ' ').strip,
    birth_date: date_from(named.("Föd").first.text.gsub(/[[:space:]]+/, ' ').strip),
    email: named.("E-post").text.gsub(/\(.*?\)/,'').sub(/[Ss]kriv/,'').sub('och lägg till','').gsub(/[[:space:]]/,''),
    term: termid,
  }
  data[:image] = URI.join(url, data[:image]).to_s unless data[:image].to_s.empty?
  ScraperWiki.save_sqlite([:id, :term], data)
end

terms = [
  [ 2007, 'http://www.lagtinget.ax/ledamot_earlier.con?iPage=132&m=257' ],
  [ 2011, 'http://www.lagtinget.ax/ledamot_az.con?iPage=104&m=262' ]
]

terms.each { |id, url| scrape_list(id, url) }
