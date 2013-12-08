#!/usr/bin/env ruby

require 'rubygems'
# require 'scraperwiki'
require 'nokogiri'
require 'pp'
require 'net/http'
require 'net/https'
require 'uri'
require 'iconv'
require 'mongo'

## Import namespace
include Mongo

class RecEvent 
    attr_accessor :id, :title, :eventCategory, :dateRange, :dayOfWeek, :timeOfDay, :location, :fee, :ageRange, :description, :contactNumber, :address, :mapUrl, :municipality
    def initialize(id, title, eventCategory, dateRange, dayOfWeek, timeOfDay, location, fee, ageRange, description, contactNumber, address, mapUrl, municipality) 
        # fee.gsub!('$', '')
        @id = id
        @title = title
        @eventCategory = eventCategory
        @dateRange = dateRange
        @dayOfWeek = dayOfWeek
        @timeOfDay = timeOfDay
        @location = location
        @fee = fee
        @ageRange = ageRange
        @description = Iconv.iconv("UTF-8//IGNORE", '', description).first
        @contactNumber = contactNumber
        @address = address
        @mapUrl = mapUrl
        @municipality = municipality
    end
end

def save_event(event)
    unique_keys = [ 'id' ]
    # data = { 
    #     'id' => event.id,
    #     'title' => event.title,
    #     'eventCategory' => event.eventCategory,
    #     'dateRange' => event.dateRange,
    #     'dayOfWeek' => event.dayOfWeek,
    #     'timeOfDay' => event.timeOfDay,
    #     'location' => event.location,
    #     'fee' => event.fee,
    #     'ageRange'=> event.ageRange,
    #     'description' => event.description,
    #     'contactNumber' => event.contactNumber,
    #     'address' => event.address,
    #     'mapUrl' => event.mapUrl
    # }

    data = { 
        'eventId' => event.id,
        'title' => event.title,
        'dateRange' => event.dateRange,
        'dayOfWeek' => event.dayOfWeek,
        'timeOfDay' => event.timeOfDay,
        'location' => event.location,
        'fee' => event.fee,
        'ageRange'=> event.ageRange,
        'description' => event.description,
        'contactNumber' => event.contactNumber,
        'address' => event.address,
        'mapUrl' => event.mapUrl,
        'eventCategory' => event.eventCategory,
        'municipality' => event.municipality
    }
    # ScraperWiki.save_sqlite(unique_keys, data)

    
	mongo_client = MongoClient.new("ds039507.mongolab.com", "39507")
	db = mongo_client.db("lvclass")
	db.authenticate("lvclassweb", "lvclassweb")
	coll = db.collection('events')

	coll.insert(data)

   #  eventId: String,
   # title: String,
   # dateRange: String,
   # dayOfWeek: String,
   # timeOfDay: String,
   # location: String,
   # fee: String,
   # ageRange: String,
   # description: String,
   # contactNumber: String,
   # address: String,
   # mapUrl: String,
   # eventCategory: String

end

def post_url_contents(url, args) 
    #url = "https://parksreg.clarkcountynv.gov/wbwsc/webtrac.wsc/wbsearch.html"

    uri = URI.parse(url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    request = Net::HTTP::Post.new(uri.path)
    #request.add_field('Content-Type', 'application/json')
    request.body = args #"per=700&xxcategory=#{category}"
    response = http.request(request)
    #puts response.body
    return response.body
end

def get_url_contents(url)
    uri = URI.parse(url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
#    pp "#{uri.path}?#{uri.query}"
    request = Net::HTTP::Get.new("#{uri.path}?#{uri.query}")


    #request.add_field('Content-Type', 'application/json')
    response = http.request(request)
    #puts response.body
    return response.body
    uri = URI.parse(url)
    response =Net::HTTP.get_response(uri)
    return response.body
end


def fetch_clark_county_events(category) 
    #html = ScraperWiki.scrape("https://parksreg.clarkcountynv.gov/wbwsc/webtrac.wsc/wbsearch.html", ["per"=>"500", "xxcategory"=> category ])
    html = post_url_contents("https://parksreg.clarkcountynv.gov/wbwsc/webtrac.wsc/wbsearch.html", "per=500&xxcategory=#{category}")
    
    doc = Nokogiri::HTML(html)
    tbodies = doc.css("tbody tr")
    puts "Total tbodies for #{category} is #{tbodies.length}"
    doc.css("tbody tr").each do |row|
        tds = row.css("td")

        detailUrl = tds[10].xpath('./a').first['href']
        detailHtml = get_url_contents(detailUrl)
        #pp detailHtml
        detailDoc = Nokogiri::HTML(detailHtml)

        rows = detailDoc.css("table td div");
        mapUrl = rows.first.xpath('./a').first['href']
        address1 = rows[1].text
        address2 = rows[2].text
        contactNumber = rows[3].text
        description = rows.last.text


        event = RecEvent.new(
            tds[2].text, # id
            tds[3].text, #name
            category, #eventCategory
            tds[4].text, #dateRange
            tds[5].text, #dayOfWeek
            tds[6].text, #timeOfDay
            tds[7].text, #location
            tds[8].text, #fee
            tds[9].text, #ageRange
            description, #description
            contactNumber, #contactNumber
            "#{address1}, #{address2}", #address
            mapUrl, #mapUrl
            'clark county' #municipality
        )
        # pp event.inspect
        save_event(event)
    end
end

def fetch_las_vegas_events(category) 
    #html = ScraperWiki.scrape("https://parksreg.clarkcountynv.gov/wbwsc/webtrac.wsc/wbsearch.html", ["per"=>"500", "xxcategory"=> category ])
    html = post_url_contents("https://recreation.lasvegasnevada.gov/wbwsc/webtrac.wsc/wbsearch.html", "per=1500&xxcategory=#{category}")
    
    doc = Nokogiri::HTML(html)
    tbodies = doc.css("tbody tr")
    puts "Total tbodies for #{category} is #{tbodies.length}"
    doc.css("tbody tr").each do |row|
        tds = row.css("td")

        detailUrl = tds[2].xpath('./a').first['href']
        detailHtml = get_url_contents(detailUrl)
        #pp detailHtml
        detailDoc = Nokogiri::HTML(detailHtml)

        ageRange = ''
        description = ''
        myTrs = detailDoc.css('table tr')
        myTrs.each_with_index do |tr|
            # puts "First: #{tr}"
            first = tr.css("td")[0]
            second = tr.css("td")[1]
            #puts first.text
            if (first.text == "Open to These Ages:")
                ageRange = second.text
            elsif (first.text == "Notes for this activity:")
                description = second.text
            end
        end

        event = RecEvent.new(
            tds[0].text, # id
            tds[1].text, #name
            category, #eventCategory
            tds[4].text, #dateRange
            tds[3].text, #dayOfWeek
            tds[5].text, #timeOfDay
            tds[6].text, #location
            tds[7].text, #fee
            ageRange, #tds[9].text, #ageRange
            description, #description
            "", #contactNumber
            "", #address
            "http://maps.google.com/?q=#{tds[6].text}", #mapUrl
            'las vegas' #municipality
        )
        save_event(event)
    end
end

def fetch_henderson_events(category) 
    #html = ScraperWiki.scrape("https://parksreg.clarkcountynv.gov/wbwsc/webtrac.wsc/wbsearch.html", ["per"=>"500", "xxcategory"=> category ])
    html = post_url_contents("https://recreation.cityofhenderson.com/wbwsc/webtrac.wsc/wbsearch.html", "per=500&xxsearch=yes&xxcategory=#{category}")
    
    doc = Nokogiri::HTML(html)
    
    tbodies = doc.css("tbody tr")
    puts "Total tbodies for #{category} is #{tbodies.length}"
    doc.css("tbody tr").each do |row|
        tds = row.css("td")
        
        detailUrl = tds[9].xpath('./a').first['href']
        detailHtml = get_url_contents(detailUrl)
        #pp detailHtml
        detailDoc = Nokogiri::HTML(detailHtml)

        
        description, table, detailTrs = ''
        myTrs = detailDoc.css('table tr')
        myTrs.each_with_index do |tr|
            # puts "First: #{tr}"
            first = tr.css("td")[0]
            second = tr.css("td")[1]
            if (first && first.text == "Details:")
                description = second.text
            elsif (first && first.text == 'Dates\Days\Times\Locations:')
                table = second
            end
        end

        contactNumber, location, mapUrl, address = ''
        if (table)
            detailTrs = table.css('tr')

            divs = detailTrs.last.css('div')

            mapUrl = divs.first.xpath('./a').first['href']
            contactNumber = divs.last.text
            address = "#{divs[1].text} #{divs[2].text}"
        end 
        
        event = RecEvent.new(
            tds[8].text, # id
            tds[2].text, #name
            category, #eventCategory
            tds[6].text, #dateRange
            tds[4].text, #dayOfWeek
            tds[5].text, #timeOfDay
            "", #location
            tds[7].text, #fee
            tds[3].text, #ageRange
            description, #description
            contactNumber, #contactNumber
            address, #address
            mapUrl, #mapUrl
            'henderson' #municipality

        )
        #puts event.inspect
        save_event(event)
    end
end

def run_clark_county
    categories = ['ADULT', 'CHILD', 'MULTI', 'SR', 'TEEN', 'T/A', 'TOT', 'YOUTH']
    #categories = ['T/A', 'CHILD'] # ~204
    #categories = ['YOUTH'] # ~ 24

    categories.each do |cat|
    #    puts "Running for #{cat}"
        fetch_clark_county_events(cat) 
    end  
end

def run_las_vegas
    categories = ['5&U', 'AD', 'SR', 'TEEN', 'YTH']
    #categories = ['TEEN']
    
    categories.each do |cat|
        fetch_las_vegas_events(cat)
    end
end

def run_henderson
    categories = ['SR', 'ADULT', 'MULTI', 'TEEN', 'YOUTH']
    #categories = ['SR']

    categories.each do |cat|
        fetch_henderson_events(cat)
    end
end

puts "Running clark county."
run_clark_county
puts "Running las vegas."
run_las_vegas
puts "Running henderson."
run_henderson

