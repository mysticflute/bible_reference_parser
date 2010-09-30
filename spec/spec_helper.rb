require 'simplecov'
SimpleCov.start do
  SimpleCov.root File.expand_path('../../', __FILE__)
  add_filter "/spec"
end

require 'rubygems'
require 'test/unit'
require 'rspec'      
require 'bible_reference_parser'

# Load shared example modules 
Dir["#{File.dirname(__FILE__)}/shared/*.rb"].each {|f| require f}