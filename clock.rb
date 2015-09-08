#!/usr/bin/env ruby 
# encoding: UTF-8

require "unicode_utils/downcase"
require "twitter"
require "json"

creds = JSON.parse File.read 'creds'

twi = Twitter::REST::Client.new do |config|
  config.consumer_key        = creds["consumer_key"]
  config.consumer_secret     = creds["consumer_secret"]
  config.access_token        = creds["access_token"] 
  config.access_token_secret = creds["access_token_secret"] 
end

stopwords = ["#смотри", "#видео", "Мои твиты:", "Телепрограмма",
	"пиздос", "пиздец", "уебан", "пидар", "пидор", "блядь",
	"ахуенно", "пиздую", "пиздуй", "блять", "ебал", "brent", 
	"нахуй"]
stopaccs = ["Kremlin_Watch", "ROIpoll", "Weather_SPB", "sergey_vorona", 
	"flymobimir", "tochnoe_vremya", "TupikovaHome"]

loop do
  time = Time.now
  puts '====================================================================================='
  puts "Current time: #{Time.now}"
  current_minute = time.strftime("%H:%M")
  previous_minute = (time - 60).strftime("%H:%M")
  time_request = "\"#{current_minute}\" OR \"#{previous_minute}\""
  begin
    twi_search = twi.search(time_request, lang: 'ru', result_type: 'recent', count: '10').take(10)
  twi_search.each do |tw|
    puts "#{tw.created_at}: #{tw.text}"
    next if stopaccs.map{|sacc| tw.user.screen_name == sacc}.any?
    next if stopwords.map{|sw| UnicodeUtils.downcase(tw.text).include? UnicodeUtils.downcase(sw)}.any?
    next if tw.text.include? Time.now.strftime("%d.%m.%Y")
    next if tw.user_mentions.any? or tw.hashtags.any? or tw.urls.any?
    # Если начинается с бля, или в тексте есть бля* без префикса
    next if UnicodeUtils.downcase(tw.text[0..2]) == "бля" or tw.text.scan(/[^А-я]бля/).count > 0
    next if tw.text.scan(/[^А-я]хуй/).count > 0
    next if tw.text.scan(/\d\d:\d\d/).count > 1
    if Time.now - tw.created_at < 120 
      if tw.text.include? current_minute or tw.text.include? previous_minute
        begin  
          twi.retweet(tw)
          break
        rescue Exception => e 
          puts e.message  
          puts e.backtrace.inspect  
        end  
      end
    end
  end
  rescue Exception => e 
    puts e.message  
    puts e.backtrace.inspect  
  end  
  sleep 15
end
