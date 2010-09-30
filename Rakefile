require 'rubygems'
require 'bundler'
Bundler.setup
require 'rake'
require 'rspec/core/rake_task'
require 'rake/rdoctask'

Rspec::Core::RakeTask.new
desc 'Run the specs.'
task :default => :spec

Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "bible_reference_parser #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "bible_reference_parser"
    gem.summary = "Parsing and validation for scripture passages."
    gem.description = "BibleReferenceParser can parse scriptures passages, such as 'Gen. 1:15-18, 21' 
                       to the individual books, chapters and verses in the passage. It also provides
                       validation for invalid book names, chapters, and verses."
    gem.email = "nathan.mcwilliams@gmail.com"
    gem.homepage = "http://github.com/endium/bible_reference_parser"
    gem.authors = ["Nathan McWilliams"]
    gem.add_development_dependency "rspec", ">= 1.2.9"
    # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

task :notes do
   system "grep -n -r 'FIXME\\|TODO\\|XXX' lib spec"
end


