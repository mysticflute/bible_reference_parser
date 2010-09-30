
module BibleReferenceParser
  
  # This class handles the parsing of verses in a string. 
  # 
  # The main method of interest is VerseReference.parse_verses. This will parse a string
  # and return a ReferenceCollection of VerseReference objects. One object for 
  # each verse identified. Example:
  # 
  #     verses = VerseReference.parse_verses("1-10, 15")
  #     verses[0].number # => 1
  #     verses[1].number # => 2
  #     verses.last.number # => 15
  #
  # You can see if there were any errors in parsing by checking the "has_errors?" method on the
  # returned ReferenceCollection. Without specify metadata to validate against, only simple 
  # validation is possible. If you do provide metadata (ex. BibleMetadata["Genesis"]) and a
  # chapter number, it can validate that the verse number actually exists for the book and chapter.
  # 
  # If you want to validate the verse references against a book reference, it's better to use
  # the parse_verses_in_reference method. This will parse the verses in a chapter reference and provide
  # the right metadata information for validation. Example:
  # 
  #     chapter = ChapterReference(1, 500, BibleMetadata["Genesis"])
  #     verses = VerseReference.parse_verses_in_reference(chapter)
  #     verses.has_errors? # => true
  #     verses.no_errors? # => false
  #     verses.errors # => ["The verse '500' does not exist for Genesis 1"]
  #
  # You can check if an individiual VerseReference has errors as well:
  #     
  #     verses.first.has_errors? # => true
  
  class VerseReference
    include TracksErrors
    
    attr_accessor :number
    
    # Initialization
    #----------------------------------------------------------------------------
    
    # Initializes a new VerseReference object. if metadata and chapter_number is provided, it will validate
    # that the verse number exists for the book and chapter.
    # 
    # You probably shouldn't be calling VerseReference.new directly. Instead, see
    # VerseReference.parse_verses or VerseReference.parse_verses_in_reference.
    # 
    # Parameters:
    # number          - The verse number.
    # metadata        - An array of metadata information for a particular book, ex. BibleMetadata["Genesis"].
    #                   This is used to validate the verse number exists for a book and chapter. If you provide
    #                   this, also provide the chapter_number parameter.
    # chapter_number  - The chapter number this verse is for. Used to validate the verse number exists for a
    #                   book and chapter. 
    def initialize(number, metadata = nil, chapter_number = nil)
      super
      
      number = number.to_i # allows passing the number parameter as string
      
      # if number is less than 1 add a parsing error and stop processing
      if number < 1
        add_error "The verse number '#{number}' is not valid"
        return
      end
      
      # if metadata and chapter number is given, we can check if the verse exists for the book and chapter.
      unless metadata.nil? || chapter_number.nil?
        total_verses_in_chapter = metadata["chapter_info"][chapter_number - 1] # subtract 1 for array offset
        if number > total_verses_in_chapter
          add_error "The verse '#{number}' does not exist for #{metadata['name']} #{chapter_number}" and return
        end
      end
  
      @number = number
    end             
    
    
    # Class Methods
    #----------------------------------------------------------------------------
    
    # Works similar to parse_verses. Use this if you want to parse the verses
    # in a ChapterReference object. It will assume we want all of the verses
    # if a chapter's raw_content is nil. But the only way we can do this is if
    # the chapter reference has metadata defined. If not, we will just assume
    # the first verse is wanted. Otherwise if raw_content is not nil, we will
    # use that. 
    def self.parse_verses_in_reference(chapter_ref)   
      unless chapter_ref.raw_content.nil?
        return self.parse_verses(chapter_ref.raw_content, chapter_ref.metadata, chapter_ref.number) 
      else      
        unless chapter_ref.metadata.nil?
          # select all the verses in the chapter
          chapter_info = chapter_ref.metadata["chapter_info"]
          total_verses = chapter_info[chapter_ref.number - 1] # -1 for the array offset          
          return self.parse_verses("1-#{total_verses}", chapter_ref.metadata, chapter_ref.number)         
        else
          # no real solution here, just assume the first verse
          return self.parse_verses 1        
        end
      end
    end  
    
    # Parse the verses in a string. Returns a ReferenceCollection
    # of VerseReference objects.
    # 
    # Parameters:
    # string          - The string to parse, ex. "1-10, 15"
    # metadata        - An array of metadata information for a particular book, ex. BibleMetadata["Genesis"].
    #                   NOTE: if you are passing this in, you probably should
    #                   be calling parse_chapters_in_reference instead of this one.
    # chapter_number  - The chapter number for the verse. Should be provided in conjunction with the metadata. 
    # 
    # Example:
    # 
    #     verses = VerseReference.parse_verses("1-10, 15")
    #     verses.first.number # => 1
    #     verses.last.number # => 15
    #     verses.length # => 11
    #
    # More Examples:
    # 
    #     VerseReference.parse_verses("1")
    #     VerseReference.parse_verses("1-10")
    #     VerseReference.parse_verses("1,5,7")
    #     VerseReference.parse_verses("1;5;7") # => same as above
    #     VerseReference.parse_verses("1-5, 10, 15-20")
    # 
    # XXX we could add an option to allow a "beginning" or "end" for ranges.
    # XXX we could allow an option to remove duplicates
    def self.parse_verses(string, metadata = nil, chapter_number = nil) 
      string = string.to_s # allows string to be passed as an int
      
      verses = ReferenceCollection.new
      
      # remove everything except for numbers and these punctuation marks -> -,;    
      string_slim = string.gsub(/[^0-9;,\-]/, "")                        
     
      # This pattern matches for verses. It first tries to match a range of verses,
      # then single verses.
      # 
      # Group 1: Verse Range ([0-9]+\-[0-9]+)
      # - Any digits then a dash then any digits
      # 
      # Group 2: Single Verse ([0-9]+)
      # - any digits
      pattern = /([0-9]+\-[0-9]+)|([0-9]+)/
      
      # find the verses
      string_slim.scan pattern do |verse_range, single_verse|        
        if verse_range
          # get the beginning and end of the range
          range = verse_range.split "-"
          first = range.first.to_i
          last = range.last.to_i

          # add each verse in the range
          (first..last).each do |number|
            verses << VerseReference.new(number, metadata, chapter_number)
          end
        else
          verses << VerseReference.new(single_verse, metadata, chapter_number)          
        end         
      end
      
      verses       
    end            
       
    
    # Instance Methods
    #----------------------------------------------------------------------------

    # Whether this reference itself is valid.
     def valid_reference?
       !number.nil?
     end
     
     # The standard clean method that all references must have. Because verses are leaf nodes and don't
     # contain other references, this method will just return an empty array. 
     def clean(chain = true)
       []
     end
              
  end  
end