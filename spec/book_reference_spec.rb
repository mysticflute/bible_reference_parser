require 'spec_helper'

include BibleReferenceParser

describe BookReference do         
  
  it_should_behave_like "it tracks errors", BookReference.new("Matthew", "1:1")
  
  describe "initialization" do

    it "should set the 'metadata' field" do
      ref = BookReference.new "Genesis", "1:1"
      ref.metadata.should_not be_nil
      ref.metadata["name"].should eql "Genesis"
    end
    
    context "for a valid book" do     
      before :each do
        @name = "Matthew"
        @short_name = "Matt."
        @raw = "1:1-10"
        @ref = BookReference.new @name, @raw
      end
         
      it "should set the 'name' field" do
        @ref.name.should eql @name
      end
    
      it "should set the 'short_name' field" do
        @ref.short_name.should eql @short_name      
      end   
    
      it "should set the 'raw_content' field" do
        @ref.raw_content.should eql @raw
      end
    
      it "should parse it's raw content" do
        @ref.chapter_references.length.should eql 1
        @ref.chapter_references.first.number.should eql 1
      end 
    end
    
    context "for an invalid book" do
      before :each do
        @ref = BookReference.new "anathema"
      end
      
      it "should add a parsing error for an invalid book name" do
        @ref.errors.first.should eql "The book 'anathema' could not be found"
      end
      
      it "should not set the 'name' field" do
        @ref.name.should be_nil
      end
      
      it "should not set the 'short_name' field" do
        @ref.short_name.should be_nil
      end
      
      it "should not set the 'raw_content' field" do
        @ref.raw_content.should be_nil
      end
      
      it "should not parse its raw_content" do
        @ref.chapter_references.should be_nil
      end         
    end
  end
  
  describe "the valid_reference? method" do
    it "should return true if the name is set" do
      book = BookReference.new "Genesis"
      book.should be_valid_reference
    end
    
    it "should return false if the name is not set" do
      book = BookReference.new "Genthesis"
      book.should_not be_valid_reference
    end
  end
  
  describe "the 'parse_contents' method" do    
    it "should set the chapter references" do
      book = BookReference.new "Matthew", "1:1-10"
      book.parse_contents     
      book.chapter_references.should_not be_nil     
    end
  end
  
  describe "when parsing the books in a passage" do
    
    describe "the parse_books method" do
      it "should correctly identify when there is only 1 book" do
        books = BookReference.parse_books("Genesis 1:1")
        books.length.should eql 1
        books.errors.length.should eql 0
      end

      it "should correctly identify when there are 2 books" do
        books = BookReference.parse_books("Genesis 1:1, Exodus 1:1")
        books.length.should eql 2    
      end

      it "should correctly identify when there are 10 books" do
        passage = "Genesis 1:1, Exodus 1:1, Leviticus 1:1, Matthew 1:1, Mark 1:1,
                   Luke 1:1;John 1:1;Rev. 1:1, 1 Sam 1:1, Prov 1:1"
                   
        books = BookReference.parse_books(passage)
        books.length.should eql 10
      end
      
      it "should contain an error if no books are specified" do
        books = BookReference.parse_books("777")
        books.errors.first.should eql "'777' does not contain any books"  
      end

      it "should parse names beginning with a number" do
        books = BookReference.parse_books("1 samuel 1:1, 2 samuel, 1cor 3, 2cor")
        books.length.should eql 4 
        books[0].name.should eql "1 Samuel"
        books[1].name.should eql "2 Samuel"
        books[2].name.should eql "1 Corinthians"
        books[3].name.should eql "2 Corinthians"      
      end

      it "should correctly identify the raw_content for a book" do
        books = BookReference.parse_books("Genesis 1:1-10, 25, 6:13; Exodus 5:14, Leviticus 1, James")
        books[0].raw_content.should eql "1:1-10,25,6:13"
        books[1].raw_content.should eql "5:14"
        books[2].raw_content.should eql "1"   
        books[3].raw_content.should be_nil
      end

      it "should correctly identify books and raw content in a complex passage, in the correct order" do
        # Books should include Genesis, Mark, Proverbs, Isaiah, Revelation, Galatians, Exodus, Hebrews, 1 Samuel
        passage = "Genesis 1:5-10, 11-15;25,;, Mark 10-21, 22,24,25, 28-32;prov2:2,\nisa9:9,rev10000,"
        passage += "galatians, exod.12-19, 21,     22;25;28,32;29,,,, hebrews1:1-10002 1 samuel 10"      
        books = BookReference.parse_books(passage)

        books.length.should eql 9

        books[0].name.should eql "Genesis"
        books[0].raw_content.should eql "1:5-10,11-15;25"

        books[1].name.should eql "Mark"
        books[1].raw_content.should eql "10-21,22,24,25,28-32"

        books[2].name.should eql "Proverbs"
        books[2].raw_content.should eql "2:2"

        books[3].name.should eql "Isaiah"
        books[3].raw_content.should eql "9:9"

        books[4].name.should eql "Revelation"
        books[4].raw_content.should eql "10000"

        books[5].name.should eql "Galatians"
        books[5].raw_content.should be_nil

        books[6].name.should eql "Exodus"
        books[6].raw_content.should eql "12-19,21,22;25;28,32;29"

        books[7].name.should eql "Hebrews"
        books[7].raw_content.should eql "1:1-10002"

        books[8].name.should eql "1 Samuel"
        books[8].raw_content.should eql "10"
      end
    end
    
    describe "each returned book" do
      it "should correctly set the name attribute" do
         books = BookReference.parse_books("Matthew 1")
         books.first.name.should eql "Matthew"
      end
        
      it "should correctly set the raw_content attribute" do
        books = BookReference.parse_books("Matthew 1:15, 2:2-20, 25")
        books.first.raw_content.should eql "1:15,2:2-20,25"
      end      
    end
    
    describe "the returned value" do
      it "should be a reference collection" do
        books = BookReference.parse_books("Genesis 1:1-10, Mark 1")
        books.should be_kind_of ReferenceCollection
      end
      
      it "should only contain BookReference objects" do
        books = BookReference.parse_books("Genesis 1:1-10, Mark 1")
        books.each do |book|
          book.should be_kind_of BookReference
        end
      end
    end 
      
  end
  
  describe "the clean method" do                        
    it "should call clean on it's chapter_references" do
      book = BookReference.new "Genesis", "1:1, 51:1"
      book.chapter_references.length.should eql 2
      
      book.clean
      book.chapter_references.length.should eql 1
      book.chapter_references.invalid_references.length.should eql 1      
    end

  end
    
end