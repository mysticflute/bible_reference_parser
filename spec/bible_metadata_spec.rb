require "spec_helper"
  
include BibleReferenceParser

describe BibleMetadata do
  before :all do
    @matthew = "Matthew"
  end
  
  it "should have valid abbreviations" do
    BibleMetadata.metadata.any? {|book| book[1].is_a?(Syck::BadAlias) }.should_not be_true
  end
  
  it "should find the correct book for an all lower-cased name" do
    info = BibleMetadata["matthew"]
    info.should_not be_nil
    info["name"].should eql @matthew
  end                                                       
  
  it "should find the correct book for a title-cased name" do
    info = BibleMetadata["Matthew"]
    info.should_not be_nil
    info["name"].should eql @matthew  
  end 
  
  it "should find the correct book for an all upper-cased name" do
    info = BibleMetadata["MATTHEW"]
    info.should_not be_nil    
    info["name"].should eql @matthew
  end
  
  it "should find the correct book for an abbreviated name" do
    info = BibleMetadata["matt"]
    info.should_not be_nil
    info["name"].should eql @matthew    
  end
  
  it "should find the correct book for an abbreviated name with a period at the end" do
    info = BibleMetadata["Matt."]
    info.should_not be_nil
    info["name"].should eql @matthew    
  end
  
  it "should find the correct book for a name given with spaces" do
    info = BibleMetadata["Song of Solomon"]
    info.should_not be_nil
    info["name"].should eql "Song of Solomon"    
  end
  
  it "should find the correct book for a name beginning with a number" do
    info = BibleMetadata["1 Samuel"]
    info.should_not be_nil
    info["name"].should eql "1 Samuel"    
  end
  
  it "should return nil for a name that can't be found" do
    info = BibleMetadata["anathema"]
    info.should be_nil
  end
  
  it "should return the book's name, short_name, number of chapters and an chapter info array" do
    info = BibleMetadata["genesis"]
    info.should_not be_nil
    info["name"].should eql "Genesis"    
    info["short_name"].should eql "Gen."
    info["chapter_info"].should be_kind_of Array
    info["chapter_info"].length.should eql 50
  end

end
