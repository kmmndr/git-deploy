#!/usr/bin/env ruby

$LOAD_PATH << File.join(File.dirname(__FILE__), 'lib')
require "language_pack"

puts "Hello ruby !!"
ENV.each do |env, value|
  puts "ENV['#{env}'] = #{value}"
end


build_dir = ENV['FULL_DIRNAME']

if pack = LanguagePack.detect(build_dir, '/tmp/git-deploy/bundler')
#if pack = LanguagePack.detect(ARGV.first)
  puts pack.name
  pack.compile
else
  puts "no"
  exit 1
end
