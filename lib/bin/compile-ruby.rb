#!/usr/bin/env ruby



puts "Hello ruby !!"
ENV.each do |env, value|
  puts "ENV['#{env}'] = #{value}"
end

$:.unshift File.expand_path("lib", __FILE__)
require "language_pack"

if pack = LanguagePack.detect(ARGV.first) 
  puts pack.name
  exit 0
else
  puts "no"
  exit 1
end   
