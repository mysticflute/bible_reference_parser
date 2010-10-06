require 'spec_helper'

include BibleReferenceParser

describe ReferenceCollection do
  it_should_behave_like "it tracks errors", ReferenceCollection.new   
  
  it "should delegate some of the Array methods" do
    ref = ReferenceCollection.new
    ref.should respond_to *%w{[] each + - << length first last empty?}
  end
    
  describe "initialization" do    
    it "should set references to an empty array by default" do
      ref = ReferenceCollection.new
      ref.references.should eql []      
    end
    
    it "should set invalid_references to an empty array by default" do
      ref = ReferenceCollection.new
      ref.invalid_references.should eql []      
    end
    
    it "should set references to the parameter passed in" do
      book = BookReference.new "Matthew"
      initial = [book]
      ref = ReferenceCollection.new(initial)
      ref.references.should eql initial      
    end
    
    it "should set the invalid_references to the parameter passed in" do
      book = BookReference.new "Matthewz"
      initial = [book]
      ref = ReferenceCollection.new([], initial)
      ref.invalid_references.should eql initial      
    end 
  end 
  
  describe "the '+' method" do    
    before :each do
      @book1 = BookReference.new "Matthew"
      @book2 = BookReference.new "Genesis"
      @ref1 = ReferenceCollection.new [@book1]
    end
    
    shared_examples_for "it delegates the + method" do
      it "should return a ReferenceCollection" do
        @ref2.should be_kind_of ReferenceCollection
      end
      
      it "should contain the new references" do
        @ref2.first.name.should eql @book1.name
      end
      
      it "should retain the existing references" do
        @ref2.last.name.should eql @book2.name
      end
      
      it "should only contain the existing and new references" do
        @ref2.length.should eql 2
      end
    end
        
    context "when adding an Array" do
      before :each do
        @ref2 = @ref1 + [@book2]
      end
      
      it_should_behave_like "it delegates the + method"            
      
      it "should retain the existing invalid references" do
        ref1 = ReferenceCollection.new [], [@book1]
        ref2 = ref1 + [@book2]
        ref2.invalid_references.length.should eql 1
        ref2.invalid_references.first.name.should eql @book1.name
      end
    end
    
    context "when adding a ReferenceCollection" do 
      before :each do
        @ref2 = @ref1 + ReferenceCollection.new([@book2])
      end
      
      it_should_behave_like "it delegates the + method"                  
      
      it "should retain the existing invalid references" do
        ref1 = ReferenceCollection.new [], [@book1]
        ref2 = ref1 + ReferenceCollection.new([@book2])
        ref2.invalid_references.length.should eql 1
        ref2.invalid_references.first.name.should eql @book1.name
      end      
    end
  end

  describe "the '-' method" do    
    before :each do
      @book1 = BookReference.new "Matthew"
      @book2 = BookReference.new "Genesis"
      @ref1 = ReferenceCollection.new [@book1, @book2]
    end

    context "when adding an Array" do
      before :each do
        @ref2 = @ref1 - [@book2]
      end
      
      it "should return a ReferenceCollection" do
        @ref2.should be_kind_of ReferenceCollection
      end
      
      it "should only contain the references not subtracted" do
        @ref2.length.should eql 1
        @ref2.first.name.should eql @book1.name
      end
            
      it "should retain the existing invalid references" do
        ref1 = ReferenceCollection.new [], [@book1]
        ref2 = ref1 - [@book2]
        ref2.invalid_references.length.should eql 1
        ref2.invalid_references.first.name.should eql @book1.name
      end
    end
    
    context "when adding a ReferenceCollection" do 
      before :each do
        @ref2 = @ref1 - ReferenceCollection.new([@book2])
      end
      
      it "should return a ReferenceCollection" do
        @ref2.should be_kind_of ReferenceCollection
      end
      
      it "should only contain the references not subtracted" do
        @ref2.length.should eql 1
        @ref2.first.name.should eql @book1.name
      end
            
      it "should retain the existing invalid references" do
        ref1 = ReferenceCollection.new [], [@book1]
        ref2 = ref1 - [@book2]
        ref2.invalid_references.length.should eql 1
        ref2.invalid_references.first.name.should eql @book1.name
      end      
    end
  end

  describe "the errors method" do    
    it "should include errors for any of the items it contains" do
      ref = ReferenceCollection.new
      book = BookReference.new "Genthesis"
      
      ref.errors.should be_empty
      ref << book
      ref.errors.first.should eql "The book 'Genthesis' could not be found"      
    end
    
    it "should include errors for invalid references" do
      book = BookReference.new "Genthesis"
      ref = ReferenceCollection.new      
      ref << book
      ref.clean
      ref.errors.first.should eql "The book 'Genthesis' could not be found"      
    end
    
    it "should not return contain duplicate errors" do
      books = BookReference.parse_books "Genesis 51"
      books.clean
      puts books.errors.inspect
      books.errors.length.should eql 1
    end    
  end
  
  describe "the 'clean' method" do
    
    describe "with the 'chain' parameter false" do
      it "should remove bad references and leave good references" do
        books = BookReference.parse_books("Genesis 1:1, Exoduth 1:1")
        books.length.should eql 2

        books.clean(false)
        books.length.should eql 1
        books.first.name.should eql "Genesis"
        books.invalid_references.length.should eql 1
      end
      
      it "should not remove any bad child references" do
        books = BookReference.parse_books("Genesis 51:1, Exodus 1:100")
        books.length.should eql 2
        
        books.clean(false)
        books.first.chapter_references.length.should eql 1
        books.first.chapter_references.invalid_references.length.should eql 0
        books.last.chapter_references.first.verse_references.length.should eql 1
        books.last.chapter_references.first.verse_references.invalid_references.length.should eql 0
      end
      
      it "should return the references that were removed" do
        books = BookReference.parse_books("Genesis 1:1, Exoduth 1:1, Numbers 100")
        cleaned = books.clean(false)
        
        cleaned.length.should eql 1
        cleaned.first.errors.first.should eql "The book 'Exoduth' could not be found"
      end
    end
    
    describe "with the 'chain' parameter true" do
      it "should remove bad references and leave good references" do
        books = BookReference.parse_books("Genesis 1:1, Exoduth 1:1")
        books.length.should eql 2

        books.clean
        books.length.should eql 1
        books.first.name.should eql "Genesis"
        books.invalid_references.length.should eql 1
      end
      
      it "should remove any bad child references" do
        books = BookReference.parse_books("Genesis 51:1, Exodus 1:100")
        books.length.should eql 2
        
        books.clean
        books.first.chapter_references.length.should eql 0
        books.first.chapter_references.invalid_references.length.should eql 1
        books.last.chapter_references.first.verse_references.length.should eql 0
        books.last.chapter_references.first.verse_references.invalid_references.length.should eql 1
      end
      
      it "should return the references that were removed" do
        books = BookReference.parse_books("Genesis 1:1, Exoduth 1:1, Numbers 100")
        cleaned = books.clean
        
        cleaned.length.should eql 2
        cleaned.first.errors.first.should eql "The book 'Exoduth' could not be found"
        cleaned.last.errors.first.should eql "Chapter '100' does not exist for the book Numbers"       
      end        
    end    
  end
end