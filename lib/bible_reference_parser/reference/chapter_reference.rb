module BibleReferenceParser
  # This class handles the parsing of chapters in a passage or string.
  # 
  # Each ChapterReference object contains the chapter number and a ReferenceCollection of
  # verses.
  # 
  # The main method of interest is ChapterReference.parse_chapters. This will parse a passage
  # or string and return a ReferenceCollection of ChapterReference objects. One object for 
  # each chapter identified. Example:
  # 
  #     chapters = ChapterReference.parse_chapters("1:1-10, 5:6")
  #     chapters[0].number # => 1
  #     chapters[1].number # => 5
  #
  # Although less useful, parse_chapters can even parse just the chapters in a complete passage:
  # 
  #     chapters = ChapterReference.parse_chapters("Genesis 1:1-10, Mark 5:6")
  #     chapters[0].number # => 1
  #     chapters[1].number # => 5 
  #
  # You can see if there were any errors in parsing by checking the "has_errors?" method on the
  # returned ReferenceCollection. Without specify metadata to validate against, only simple 
  # validation is possible. If you do provide metadata, (ex. BibleMetadata["Genesis"]),
  # The ChapterReference will add an error message if the chapter doesn't exist for the book.
  # 
  # If you want to parse chapters for a particular book, its better to use the 
  # parse_chapters_in_reference method. This method takes an existing book reference. 
  # Example:
  # 
  #     book = BookReference.new("Genesis", "1:1000, 51:10")
  #     chapters = ChapterReference.parse_chapters_in_reference(book)
  #     chapters.has_errors? # => true
  #     chapters.no_errors? # => false
  #     chapters.errors # => ["The verse '1000' does not exist for Genesis 1",
  #                           "Chapter '51' does not exist for the book Genesis"]
  #
  # You can check if an individiual ChapterReference has errors as well:
  # 
  #     book = BookReference.new("Genesis", "1:1000, 51:10")
  #     chapters = ChapterReference.parse_chapters_in_reference(book)
  #     chapters.first.has_errors? # => true
  #     chapters.first.no_errors # => false
  #     chapters.first.errors # => ["The verse '1000' does not exist for Genesis 1"]
  
  class ChapterReference 
    include TracksErrors
    
    attr_reader :number, :raw_content, :verse_references, :metadata 
    
    alias :children :verse_references
    
    # Instance Initialization
    #----------------------------------------------------------------------------
    
    # Initializes a new ChapterReference object.
    #
    # Parameters:
    # number        - The chapter number. Can either be an string or integer
    # raw_content   - A string representing the verses referenced, ex. "1-10"
    # metadata      - (optional) An array of metadata information for a particular
    #                 book, ex. BibleMetadata["Genesis"]. This is used to check if
    #                 the chapter number is valid for a book.
    def initialize(number, raw_content = nil, metadata = nil)
      super
                   
      number = number.to_i # allows passing the number parameter as string
      
      # if number is less than 1 add a parsing error and stop processing
      if number < 1
        add_error "The chapter number '#{number}' is not valid" and return
      end
      
      # metadata info for a particular book in the bible
      @metadata = metadata
      
      # if the metadata is given, we can verify if the chapter exists for the book
      unless @metadata.nil?        
        total_chapters_in_book = @metadata["chapter_info"].length
        
        if number > total_chapters_in_book
          add_error "Chapter '#{number}' does not exist for the book #{@metadata['name']}" and return
        end
      end        
      
      # The chapter number
      @number = number
      
      # The string representing the verses referenced in this chapter    
      @raw_content = raw_content
      
      parse_contents      
    end
    
    # Class Methods
    #----------------------------------------------------------------------------        
                                                          
    # Works similar to parse_chapters, however this should be used instead if you want
    # to associate the chapter references with a book. This will decide what chapters 
    # are referenced based on the raw_content of the book reference. If the raw_content
    # is nil, it will assume only the first chapter is desired.
    def self.parse_chapters_in_reference(book_reference)
      if book_reference.raw_content.nil?                          
        # if the raw_content is nil, assume we want just the first chapter. This is what
        # Bible Gateway does if you just give a book name.
        return self.parse_chapters(1, book_reference.metadata)        
      else
        return self.parse_chapters(book_reference.raw_content, book_reference.metadata)        
      end
    end
    
    # Parse the chapters in a passage or string. Returns a ReferenceCollection
    # of ChapterReference objects.
    # 
    # Parameters:
    # passage         - The passage to parse, ex. "1:1-10, 2:5-7"
    # metadata        - An array of metadata information for a particular book, ex. BibleMetadata["Genesis"].
    #                   NOTE: if you are passing this in, you probably should
    #                   be calling parse_chapters_in_reference instead of this one. 
    # 
    # Example:
    # 
    #     chapters = ChapterReference.parse_chapters("1:1-10, 2:5-7")
    #     chapters.first.number # => 1
    # 
    # This can also parse just the chapters in a whole passage. It will ignore the book names:
    # 
    #     chapters = ChapterReference.parse_chapters("Genesis 1:1-10; mark 1:5-7")
    #     chapters.first.number # => 1
    #
    # More Examples:
    # 
    #     ChapterReference.parse_chapters("1:1")
    #     ChapterReference.parse_chapters("1:1-10")
    #     ChapterReference.parse_chapters("1:1-10; 5-10")
    #     ChapterReference.parse_chapters("1:5,8,11; 2:10, 5-20")
    #     ChapterReference.parse_chapters(10)
    # 
    # XXX allow option to remove duplicate chapters
    def self.parse_chapters(passage, metadata = nil)
      passage = passage.to_s # allows for integer passage
      
      chapters = ReferenceCollection.new
      
      # ~ Do some massaging of the data before we scan it...
      
      # Replace letters with a semi-colon. We would just remove all letters, but in cases
      # where books are separated by just a space, it will cause errors. For example
      # "Genesis 1 Exodus 1" would end up as "11".
      passage = passage.gsub(/[a-zA-Z]+/, ";") 
      
      # Next remove everything except for numbers and these punctuation marks -> -,;:
      # We don't care about spaces or any other characters.   
      passage = passage.gsub(/[^0-9:;,\-]/, "")
      
      # Finally insert a semi-colon before digits that precede a colon. This is for chapters
      # that reference specific verses, like "15:1". Semi-colons are used to indicate
      # the following sequence is separate from the preceding sequence. This is important
      # for back-to-back chapters with verses, ex. "1:5,10,5:10". Here we want chapter 1
      # verses 5 and 10, then chapter 5 verse 10. The way we know it's not chapter 1 verse
      # 5, 10, and 5 is if there is a semi-colon there: "1:5,10,;5:10".
      passage = passage.gsub(/[0-9]+:/, ';\0')
      
      # This will look for digits followed by a semi-colon. If we match that,
      # we know what's before the colon is the chapter, and we know every digit or dash
      # directly after it are the verses.       
      match_chapter_with_verses = /([0-9]+:)([0-9,\-]+)/
      
      # This will match a chapter range, like "1-10"
      match_chapter_range = /([0-9]+\-[0-9]+)/
      
      # This will match a single chapter selection that doesn't specify any verses.
      # Something like "Genesis 1, 2" tells us we want chapters 1 and chapter 2. 
      # It looks for any digits directly followed by an optional comma or semi-colon. 
      # It's optional because it won't be there if it's the last or only chapter.
      match_single_chapter = /([0-9]+[,;]?)/
      
      # First try to match the chapter with verses, then the chapter range, then finally the single chapter
      pattern = Regexp.union(match_chapter_with_verses, match_chapter_range, match_single_chapter)
      
      # Let's find the chapters already!
      passage.scan pattern do |with_verses, verses, chapter_range, without_verses|
       
        if chapter_range
          # get the beginning and end of the range
          range = chapter_range.split "-"
          first = range.first.to_i
          last = range.last.to_i
          
          # add each chapter in the range
          (first..last).each do |number|
            chapters << ChapterReference.new(number, nil, metadata)
          end
        else
          number = with_verses ? with_verses.to_i : without_verses.to_i
          
          # remove all characters from the end util we get to a number.
          # This basically removes any extraneous punctation at the end.        
          verses = verses.gsub(/[^0-9]+$/, "") unless verses.nil?
          
          chapters << ChapterReference.new(number, verses, metadata)      
        end
      end
      
      chapters      
    end                                  
    
    # Instance Methods
    #----------------------------------------------------------------------------
    
    # Whether this reference itself is valid. Please note this does not consider the verses inside
    # the chapter, just the chapter itself.
    def valid_reference?
      !number.nil?
    end
    
    # Parse the raw_content in order to find the verses referenced for this chapter. 
    def parse_contents
      @verse_references = VerseReference.parse_verses_in_reference self
    end
    
    # Cleans invalid verse references. After calling this, the verse_references method will only return good
    # verse references. You can access the invalid references through verse_references.invalid_references. 
    # See ReferenceCollection.clean for more information.
    # 
    # If the chain parameter is true (which it is by default) it will also tell valid verses to do a clean. 
    # Since verses are leaf-nodes so to speak, they don't contain any references to clean so it won't do anything.
    def clean(chain = true)
      verse_references.clean(chain)
    end
    
    # TODO write specs
    # Get an array of ints containing the verse numbers referenced
    def verse_numbers  
      verses = []
      @verse_references.each do |ref|
        verses << ref.number
      end
      verses
    end

  end  
end