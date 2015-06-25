#!/bin/env ruby
# encoding: utf-8

require 'scraperwiki'
require 'nokogiri'
require 'open-uri'

require 'pry'
require 'open-uri/cached'
OpenURI::Cache.cache_path = '.cache'

def noko_for(url)
  Nokogiri::HTML(open(url).read) 
end

def date_from(date)
  return if date.nil? || date.empty?
  Date.parse(date).to_s
end

def scrape_list(t)
  puts "Scraping #{t[:id]}"
  noko = noko_for(t[:source])
  noko.css('#ledamots a/@href').map(&:text).each do |link|
    scrape_mp(t, URI.join(t[:source], link).to_s)
  end
 end

def scrape_mp(t, url)
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
    term: t[:id],
  }
  data[:image] = URI.join(url, data[:image]).to_s unless data[:image].to_s.empty?
  ScraperWiki.save_sqlite([:id, :term], data)
end

terms = [{
  id: 2007,
  name: '2007–2011',
  start_date: '2007',
  end_date: '2011',
  source: 'http://www.lagtinget.ax/ledamot_earlier.con?iPage=132&m=257',
},{
  id: 2011,
  name: '2011–',
  start_date: '2011',
  source: 'http://www.lagtinget.ax/ledamot_az.con?iPage=104&m=262',
}]
ScraperWiki.save_sqlite([:id], terms, 'terms')

terms.each do |t|
  scrape_list(t)
end
