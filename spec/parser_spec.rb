require 'spec_helper'

describe BibleReferenceParser do
  specify "the 'parse' method should parse books" do
    books = BibleReferenceParser.parse("Genesis 1:1, Matthew 1:1")
    books.length.should eql 2    
  end
  
  specify "the 'parse_books' method should parse books" do
    books = BibleReferenceParser.parse_books("Genesis 1:1, Matthew 1:1")
    books.length.should eql 2    
  end
  
  specify "the 'parse_chapters' method should parse books" do
    chapters = BibleReferenceParser.parse_chapters("1-3, 7:15")
    chapters.length.should eql 4   
  end
  
  specify "the 'parse_verses' method should parse books" do
    verses = BibleReferenceParser.parse_verses("1-10, 20")
    verses.length.should eql 11
  end 
end