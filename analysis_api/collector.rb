# collector.rb
#
# This requests points for each post in a corpus, corpus name (folder) is
# passed as an argument

require "json"
require 'net/http'

unless ARGV[0]
  puts "missing corpus argument"
  puts "try: ruby collector.rb abortion"
  exit
end

path = "#{ARGV[0]}/*"
puts "Path: #{path}"
posts = []

# aggregate all the posts in the corpus
Dir.glob(path) do |f|
  next unless f.include? "json"
  post = JSON.parse(File.open(f).read)
  posts << post if post["content"].length > 30
end

# collect text from the corpus to use in modeling topics
topic_text = posts.map { |p| p["content"] }.join("\n").gsub(/[^\w']/, " ").gsub(/\s+/, " ").downcase[0..60000]

# setup a connection to the topic API
uri = URI('http://topic_api:4567/')
http = Net::HTTP.new(uri.host, uri.port)
topic_query = { text: topic_text, topic_count: 8, top_word_count: 8 }.to_json

# Request the topics from the topic API
req = Net::HTTP::Post.new(uri)
req.body = topic_query
topics = JSON.parse(http.request(req).body)["topics"]

# Create the output file for topics and points
out_file = File.open("#{ARGV[0]}_points.txt", "w")

out_file.write("#{topics.join(",")}\n")

# Setup a connection to the points API
uri = URI('http://points_api:4567/')
http = Net::HTTP.new(uri.host, uri.port)

# for each post, extract the points using the points API
posts.each_with_index do |post, index|
  query = { text: post["content"], topics: topics, keys: %w(string pattern) }.to_json
  req = Net::HTTP::Post.new(uri)
  req.body = query
  data = JSON.parse(http.request(req).body)
  # write the result of each to file
  data.map { |p| out_file.write("#{p.merge(post).to_json},\n") }
end