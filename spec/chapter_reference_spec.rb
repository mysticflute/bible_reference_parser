require 'spec_helper'

include BibleReferenceParser

describe ChapterReference do  
  
  it_should_behave_like "it tracks errors", ChapterReference.new(1, "1-10,15"), ChapterReference.new(0)
  
  describe "initialization" do

    it "should set the 'metadata' field" do
      metadata = BibleMetadata["Genesis"]
      chapter = ChapterReference.new 1, "10-12", metadata
      chapter.metadata.should eql metadata
    end
        
    context "for a valid chapter" do
      before :each do
        @number = 10
        @raw = "10-12"
        @chapter = ChapterReference.new @number, @raw
      end
               
      it "should set the 'number' field" do
        @chapter.number.should eql @number      
      end

      it "should set the 'raw_content' field" do
        @chapter.raw_content.should eql @raw  
      end
      
      it "should parse it's raw_content" do
        @chapter.verse_references.length.should eql 3
        @chapter.verse_references.first.number.should eql 10
      end
      
      it "should convert a string chapter number to an integer" do
        chapter = ChapterReference.new "10"
        chapter.number.should eql 10      
      end  
    end
    
    context "for an invalid chapter" do
      it "should set an error for a chapter number equal to 0" do
        chapter = ChapterReference.new 0
        chapter.errors.first.should eql "The chapter number '0' is not valid"
      end
            
      it "should set an error for a chapter number below 0" do
        chapter = ChapterReference.new -5
        chapter.errors.first.should eql "The chapter number '-5' is not valid"
      end
          
      it "should set an error if the chapter doesn't exist for the book" do
        chapter = ChapterReference.new 51, "10-12", BibleMetadata["Genesis"]
        chapter.errors.first.should eql "Chapter '51' does not exist for the book Genesis"        
      end
      
      it "should not set the number field" do
        chapter = ChapterReference.new "invalid"
        chapter.number.should be_nil
      end
      
      it "should not set the raw_content field" do
        chapter = ChapterReference.new "invalid"        
        chapter.raw_content.should be_nil
      end
      
      it "should not parse its raw_content for invalid chapters" do
        chapter = ChapterReference.new 0
        chapter.verse_references.should be_nil
      end
    end                                                           
  end
  
  describe "the valid_reference? method" do
    it "should be true if the chapter number is valid" do
      chapter = ChapterReference.new 1
      chapter.should be_valid_reference      
    end
    
    it "should be false if the chapter number is not valid" do
      chapter = ChapterReference.new 0
      chapter.should_not be_valid_reference      
    end
  end
  
  describe "the 'parse_contents' method" do
    it "should set the verse_references field" do
      chapter = ChapterReference.new 1, "1-10"
      chapter.parse_contents
      chapter.verse_references.should_not be_nil
    end
  end

  describe "when parsing the chapters in a passage" do
    
    describe "the parse_chapters method" do
      it "should recognize the chapters in a simple string" do
        chapters = ChapterReference.parse_chapters "1:10"
        chapters.length.should eql 1       
        chapters.first.number.should eql 1       
      end
      
      it "should recognize chapters with spaces" do
        chapters = ChapterReference.parse_chapters "1:1, 2:1, 3:1"
        chapters.length.should eql 3
      end
      
      it "should recognize chapters without spaces" do
        chapters = ChapterReference.parse_chapters "1:1,2:1,3:1"
        chapters.length.should eql 3
      end                                                       
  
      it "should recognize 5 chapters" do
        chapters = ChapterReference.parse_chapters "1:10, 2:20, 3:30, 4:4-10, 5:6-10"
        chapters.length.should eql 5
      end
  
      it "should recognize chapters that don't have any verses defined" do
        chapters = ChapterReference.parse_chapters "1, 2, 3, 4, 5, 6, 7, 8"
        chapters.length.should eql 8
        chapters[0].number.should eql 1
        chapters[1].number.should eql 2
        chapters[2].number.should eql 3
        chapters[3].number.should eql 4
        chapters[4].number.should eql 5
        chapters[5].number.should eql 6
        chapters[6].number.should eql 7
        chapters[7].number.should eql 8
      end
      
      it "should recognize a new chapter after a semi-colon" do
        chapters = ChapterReference.parse_chapters "1:1,5,10;12"
        chapters.length.should eql 2
        chapters.first.number.should eql 1
        chapters.first.raw_content.should eql "1,5,10"
        chapters.last.number.should eql 12
        chapters.last.raw_content.should be_nil
      end
      
      it "should recognize a mixture of chapters with and without verses" do
        chapters = ChapterReference.parse_chapters "1, 3:1-10; 5, 6:10,12,15, 8:10,11;15;16:1"
        chapters.length.should eql 7
        
        chapters[0].number.should eql 1
        chapters[0].raw_content.should be_nil

        chapters[1].number.should eql 3
        chapters[1].raw_content.should eql "1-10"
                
        chapters[2].number.should eql 5
        chapters[2].raw_content.should be_nil
        
        chapters[3].number.should eql 6
        chapters[3].raw_content.should eql "10,12,15"
        
        chapters[4].number.should eql 8
        chapters[4].raw_content.should eql "10,11"
        
        chapters[5].number.should eql 15
        chapters[5].raw_content.should be_nil
        
        chapters[6].number.should eql 16
        chapters[6].raw_content.should eql "1"
      end
      
      it "should recognize passages beginning and ending with a single chapter" do
        chapters = ChapterReference.parse_chapters "1, 5:10-12; 15"
        chapters.length.should eql 3
        chapters[0].number.should eql 1
        chapters[1].number.should eql 5
        chapters[1].raw_content.should eql "10-12"
        chapters[2].number.should eql 15
      end
      
      it "should recognize passages beginning and ending with a chapter with verses" do
        chapters = ChapterReference.parse_chapters "1:1;5;6:10"
        chapters.length.should eql 3
        chapters[0].number.should eql 1
        chapters[0].raw_content.should eql "1"
        chapters[1].number.should eql 5
        chapters[1].raw_content.should be_nil
        chapters[2].number.should eql 6
        chapters[2].raw_content.should eql "10"
      end
  
      it "should recognize a simple range of chapters" do
        chapters = ChapterReference.parse_chapters("1-5")
        chapters.length.should eql 5
        chapters[0].number.should eql 1
        chapters[1].number.should eql 2
        chapters[2].number.should eql 3
        chapters[3].number.should eql 4
        chapters[4].number.should eql 5      
      end 
      
      it "should recognize multiple digit ranges" do
        chapters = ChapterReference.parse_chapters "90-110"
        chapters.length.should eql 21        
      end 
    
      it "should recognize a complex range of chapters" do
         chapters = ChapterReference.parse_chapters("1:10, 2:20-25; 4-7, 12:16; 15-17;; 19, 22, 25-28, 30")
         chapters.length.should eql 17 
       
         chapters[0].number.should eql 1
         chapters[0].raw_content.should eql "10"
       
         chapters[1].number.should eql 2
         chapters[1].raw_content.should eql "20-25"
       
         chapters[2].number.should eql 4
         chapters[2].raw_content.should be_nil
       
         chapters[3].number.should eql 5
         chapters[3].raw_content.should be_nil
       
         chapters[4].number.should eql 6
         chapters[4].raw_content.should be_nil
       
         chapters[5].number.should eql 7
         chapters[5].raw_content.should be_nil
       
         chapters[6].number.should eql 12
         chapters[6].raw_content.should eql "16"
       
         chapters[7].number.should eql 15
         chapters[7].raw_content.should be_nil
       
         chapters[8].number.should eql 16
         chapters[8].raw_content.should be_nil
       
         chapters[9].number.should eql 17
         chapters[9].raw_content.should be_nil       
       
         chapters[10].number.should eql 19
         chapters[10].raw_content.should be_nil
              
         chapters[11].number.should eql 22
         chapters[11].raw_content.should be_nil
       
         chapters[12].number.should eql 25
         chapters[12].raw_content.should be_nil
       
         chapters[13].number.should eql 26
         chapters[13].raw_content.should be_nil
       
         chapters[14].number.should eql 27
         chapters[14].raw_content.should be_nil
       
         chapters[15].number.should eql 28
         chapters[15].raw_content.should be_nil
       
         chapters[16].number.should eql 30
         chapters[16].raw_content.should be_nil       
      end
      
      it "should recognize two back-to-back double digit chapters with verses" do
        chapters = ChapterReference.parse_chapters "15:1-5,15, 20:1-10,15"        
        chapters.length.should eql 2
        chapters.first.number.should eql 15
        chapters.first.raw_content.should eql "1-5,15"
        chapters.last.number.should eql 20
        chapters.last.raw_content.should eql "1-10,15"
      end
      
      it "should recognize chapters and raw_content in a complex string in the correct order" do 
        # chapters are 1, 2, 3, 4, 5, 6, 7, 8, 9, 25, 14, 19, 100,10000
        string = "1, 2:10,12,   3:13, 4:1-10, 20\n;5, 6;7;8:10000;9;25:12;;;14:1-21,19:20-26,;,100,10000"
        chapters = ChapterReference.parse_chapters string
     
        chapters.length.should eql 14
        chapters[0].number.should eql 1
        chapters[0].raw_content.should be_nil
     
        chapters[1].number.should eql 2
        chapters[1].raw_content.should eql "10,12"
     
        chapters[2].number.should eql 3
        chapters[2].raw_content.should eql "13"
     
        chapters[3].number.should eql 4
        chapters[3].raw_content.should eql "1-10,20"
     
        chapters[4].number.should eql 5
        chapters[4].raw_content.should be_nil
     
        chapters[5].number.should eql 6
        chapters[5].raw_content.should be_nil
     
        chapters[6].number.should eql 7
        chapters[6].raw_content.should be_nil
     
        chapters[7].number.should eql 8
        chapters[7].raw_content.should eql "10000"
     
        chapters[8].number.should eql 9
        chapters[8].raw_content.should be_nil
     
        chapters[9].number.should eql 25
        chapters[9].raw_content.should eql "12"
     
        chapters[10].number.should eql 14
        chapters[10].raw_content.should eql "1-21"
     
        chapters[11].number.should eql 19
        chapters[11].raw_content.should eql "20-26"
     
        chapters[12].number.should eql 100
        chapters[12].raw_content.should be_nil
     
        chapters[13].number.should eql 10000
        chapters[13].raw_content.should be_nil       
    
      end                   
    
      it "should recognize chapters and raw_content in a passage with book names" do
        chapters = ChapterReference.parse_chapters("Gen. 1:10, Mark 2:2-10, James 3 Gal 1")
      
        chapters[0].number.should eql 1
        chapters[0].raw_content.should eql "10"
      
        chapters[1].number.should eql 2
        chapters[1].raw_content.should eql "2-10"
      
        chapters[2].number.should eql 3
        chapters[2].raw_content.should be_nil
      
        chapters[3].number.should eql 1
        chapters[3].raw_content.should be_nil
      end                                          
      
      it "should convert an int passage to a string" do
        chapters = ChapterReference.parse_chapters 10
        chapters.first.number.should eql 10
      end
    end
    
    describe "the parse_chapters_in_reference method" do
      it "should parse the right raw_content" do
        book =  BookReference.new "Matthew", "1:1-10"
        chapters = ChapterReference.parse_chapters_in_reference book
        chapters.first.number.should eql 1
        chapters.first.raw_content.should eql "1-10"
      end
      
      it "should use the right book metadata" do
        book = BookReference.new "Genesis", "51:1"
        chapters = ChapterReference.parse_chapters_in_reference book 
        chapters.first.errors.first.should eql "Chapter '51' does not exist for the book Genesis"        
      end
      
      it "should assume chapter 1 for book references with nil raw_content" do
        book = BookReference.new "Matthew"
        chapters = ChapterReference.parse_chapters_in_reference book
        chapters.length.should eql 1
        chapters.first.number.should eql 1
      end
    end
    
    describe "each returned chapter" do
      it "should correctly set the number attribute" do
        chapters = ChapterReference.parse_chapters "1:1"
        chapters.first.number.should eql 1
      end
      
      it "should correctly set the raw_content attribute" do
        chapters = ChapterReference.parse_chapters "1:1-5"
        chapters.first.raw_content.should eql "1-5"
      end 
      
      it "should set the raw_content attribute to nil for a range" do
        chapters = ChapterReference.parse_chapters "1-10"
        chapters.first.raw_content.should be_nil        
      end
      
      it "should correctly set the metadata attribute" do
        metadata = BibleMetadata["Matthew"]
        chapters = ChapterReference.parse_chapters "1:1", metadata
        chapters.first.metadata.should eql metadata
      end
    end
    
    describe "the returned value" do
      it "should be a reference collection" do
        chapters = ChapterReference.parse_chapters("1:1-10, 12:15")
        chapters.should be_kind_of ReferenceCollection
      end
      
      it "should only contain ChapterReference objects" do
        chapters = ChapterReference.parse_chapters("1:1-10, 12:15")
        chapters.each do |chapter|
          chapter.should be_kind_of ChapterReference
        end
      end
    end
          
  end    

  describe "the 'clean' method" do
    it "should call clean on it's verse references" do
      chapter = ChapterReference.new 1, "23-26", BibleMetadata["Matthew"]
      chapter.verse_references.length.should eql 4

      chapter.clean
      chapter.verse_references.length.should eql 3
      chapter.verse_references.invalid_references.length.should eql 1
    end
  end
end