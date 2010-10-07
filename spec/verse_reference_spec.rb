require 'spec_helper'

include BibleReferenceParser

describe VerseReference do
  
  it_should_behave_like "it tracks errors", VerseReference.new(1), VerseReference.new(0)
  
  describe "initialization" do
    context "for a valid verse" do
      it "should convert a string verse number to an integer" do
        verse = VerseReference.new "10"
        verse.number.should eql 10      
      end
      
      it "should set the number field" do
        verse = VerseReference.new 1
        verse.number.should eql 1
      end           
    end
    
    context "for an invalid verse" do
      it "should add an error for a number less than 0" do
        verse = VerseReference.new -1
        verse.errors.first.should eql "The verse number '-1' is not valid"
      end

      it "should add an error for a number equal to 0" do
        verse = VerseReference.new 0
        verse.errors.first.should eql "The verse number '0' is not valid"      
      end
      
      it "should add an error if the verse is not valid for a book/chapter" do
        verse = VerseReference.new 18, BibleMetadata["Matthew"], 3
        verse.errors.first.should eql "The verse '18' does not exist for Matthew 3"
      end
      
      it "should not set the number field" do
        verse = VerseReference.new 0
        verse.number.should be_nil        
      end     
    end
  end
  
  describe "the valid_reference? method" do
    it "should return true if the verse number is valid" do
      verse = VerseReference.new 1
      verse.should be_valid_reference
    end
    
    it "should return false if the verse is invalid" do
      verse = VerseReference.new 0
      verse.should_not be_valid_reference
    end
  end
  
  describe "when parsing the verses in a string" do
   
    describe "the parse_verses method" do
      it "should add an error if the last verse in a range is lower than the first" do
        verses = VerseReference.parse_verses "2-1"
        verses.errors(false).length.should eql 1
        verses.errors(false).first.should eql "'2-1' is an invalid range of verses"
        verses.should be_empty
      end
      
      it "should parse single verses" do
        verses = VerseReference.parse_verses "1, 2,3"
        verses.length.should eql 3
        verses[0].number.should eql 1
        verses[1].number.should eql 2
        verses[2].number.should eql 3        
      end
      
      it "should parse single verses that has semi-colons instead of commas" do
        verses = VerseReference.parse_verses "1;2; 3"
        verses.length.should eql 3
        verses[0].number.should eql 1
        verses[1].number.should eql 2
        verses[2].number.should eql 3
      end
      
      it "should parse a range of verses" do
        verses = VerseReference.parse_verses "1-5"
        verses.length.should eql 5
        verses[0].number.should eql 1
        verses[1].number.should eql 2
        verses[2].number.should eql 3
        verses[3].number.should eql 4
        verses[4].number.should eql 5      
      end
      
      it "should parse a combination of ranges and single verses" do
        verses = VerseReference.parse_verses "1, 2, 5-7 ;9,  11, 15-17"
        verses.length.should eql 10
        verses[0].number.should eql 1
        verses[1].number.should eql 2
        verses[2].number.should eql 5
        verses[3].number.should eql 6
        verses[4].number.should eql 7
        verses[5].number.should eql 9
        verses[6].number.should eql 11
        verses[7].number.should eql 15
        verses[8].number.should eql 16
        verses[9].number.should eql 17    
      end
      
      it "should parse a string beginning and ending with a range" do
        verses = VerseReference.parse_verses "1-3, 5, 7-8"
        verses.length.should eql 6
        verses[0].number.should eql 1
        verses[1].number.should eql 2
        verses[2].number.should eql 3
        verses[3].number.should eql 5
        verses[4].number.should eql 7
        verses[5].number.should eql 8
      end
      
      it "should parse a string beginning and ending with a single verse" do
        verses = VerseReference.parse_verses "1, 3-4, 7"
        verses.length.should eql 4
        verses[0].number.should eql 1
        verses[1].number.should eql 3
        verses[2].number.should eql 4
        verses[3].number.should eql 7        
      end
      
      it "should parse a range that has the same beginning and end" do
        verses = VerseReference.parse_verses "1, 7-7"
        verses.length.should eql 2
        verses[0].number.should eql 1
        verses[1].number.should eql 7
      end
    end
    
    describe "the parse_verses_in_reference method" do
      before :each do
        @chapter = ChapterReference.new "1", "1, 3-5"
        @verses = VerseReference.parse_verses_in_reference @chapter      
      end

      it "should parse the right raw_content" do
        @verses.first.number.should eql 1
        @verses.last.number.should eql 5
      end

      it "should assume all verses for a chapter with nil raw_content and chapter metadata isn't nil" do
        chapter = ChapterReference.new 1, nil, BibleMetadata["Matthew"]
        verses = VerseReference.parse_verses_in_reference chapter
        verses.length.should eql 25                
      end
      
      it "should assume just the first verse for a chapter with nil raw_content and chapter metadata is nil" do
        chapter = ChapterReference.new 1, nil
        verses = VerseReference.parse_verses_in_reference chapter
        verses.length.should eql 1        
      end
    end
    
    describe "each returned verse" do
      it "should correctly set the number attribute" do
        verses = VerseReference.parse_verses "1-3"
        verses.first.number.should eql 1
      end
    end
    
    describe "the returned value" do
      it "should be a reference collection" do
        verses = VerseReference.parse_verses("1-10, 15")
        verses.should be_kind_of ReferenceCollection
      end
      
      it "should only contain VerseReference objects" do
        verses = VerseReference.parse_verses("1-10, 15")
        verses.each do |verse|
          verse.should be_kind_of VerseReference
        end
      end
    end
      
  end

  describe "the 'clean' method" do
    it "should return an empty array" do
      verse = VerseReference.new 1
      verse.clean.should eql []
    end
  end
end