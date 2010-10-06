module BibleReferenceParser
 
  # This class handles parsing the books in a passage reference.
  # 
  # Each BookReference contains the book's name, short name (abbreviation), and a ReferenceCollection
  # of chapters.
  # 
  # The main method of interest is BookReference.parse_books. This will 
  # parse a passage and return a ReferenceCollection containing BookReference objects;
  # one object for every book found in the passage. Example:                                                                     
  # 
  #     books = BookReference.parse_books("Matt. 1:1-10, Revelation 5:6-11, Luke 7:7")
  #     books[0].name # => "Matthew"
  #     books[1].short_name # => "Rev."
  #     books[2].name # => "Luke"
  # 
  # Access the chapter references found through the chapter_references method:
  # 
  #     books.chapter_references
  #     books.children # => alias for chapter_references
  #
  # You can see if there were any errors in parsing by checking the "has_errors?" method on the returned
  # ReferenceCollection. Example:
  # 
  #     books = BookReference.parse_books("Gethensis 1:1, Matthew 1:5000")
  #     books.has_errors? # => true
  #     books.no_errors? # => false
  #     books.errors # => ["The book 'Genthesis' could not be found", "The verse '5000' does not exist for Matthew 1"]
  # 
  # You can check if an individiual BookReference has errors as well:
  # 
  #     books = BookReference.parse_books("Gethensis 1:1, Matthew 1:5000")
  #     books.first.has_errors? # => true
  #     books.first.errors # => ["The book 'Genthesis' could not be found"]
  
  class BookReference
    include TracksErrors
    
    attr_reader :name, :short_name, :raw_content, :chapter_references, :metadata
    
    alias :children :chapter_references  
     
    # Instance Initialization
    #----------------------------------------------------------------------------
    
    # Initializes a new BookReference object. If the book cannot be found, a parsing error will occur.
    # 
    # Parameters:
    # book_name   - can be either the full name or the abbreviation.
    # raw_content - the raw string of chapters/verses selected for this book reference (ex. "1:1-10").                    
    def initialize(book_name, raw_content = nil)
      super
            
      # get the metadata for the given book name
      @metadata = BibleMetadata[book_name]
      
      # if the book doesn't exist add a parsing error and stop processing
      if @metadata.nil?
        add_error "The book '#{book_name}' could not be found" and return
      end
      
      # name of the book, ex. Genesis
      @name = metadata["name"]
      
      # abbreviated name of the book, ex. Gen.
      @short_name = metadata["short_name"]
      
      # the string representing the chapters/verses for this reference, ex. "1:1-10"
      @raw_content = raw_content
      
      parse_contents
    end 
     
        
    # Class Methods
    #----------------------------------------------------------------------------           
                               
    # Parse the books in a passage. Returns a ReferenceCollection of BookReference objects.
    # 
    # Parameters:
    # passage - The passage to parse, ex. "Genesis 1:1-10, Exodus 1:5-7"
    # 
    # Example:
    # 
    #     books = BookReference.parse_books("Genesis 1:1-10, mark 1:5-7")
    #     books.first.name # => "Genesis"  
    # 
    # The above example will return a ReferenceCollection of two BookReference objects, one for
    # each book identified in the passage.
    # 
    # More Examples:
    # 
    #     Book.parse_books("Matt 1")
    #     Book.parse_books("Gen. 1-5, Ex. 7:14")
    #     Book.parse_books("Genesis 1:1-15, 2:12, Exod. 7:14")
    #     Book.parse_books("gen 5, exodus") # => will assume Exodus 1
    #     Book.parse_books("gen. 1-5, gen 9:1") # => two different references to genesis 
    #     Book.parse_books("[rev1:15][daniel  12: 1]") # => white space and unnecessary punctuation is ignored
    def self.parse_books(passage)

      books = ReferenceCollection.new
      
      # remove everything except for numbers, letters and these punctuation marks -> -,;:    
      passage_slim = passage.gsub(/[^0-9a-zA-Z:;,\-]/, "")
                       
      # This pattern matches for book name and chapter/verses pairs. It consists of two capture groups:
      # 
      # Group 1: Book's name ([0-9]?[a-zA-Z]+)      
      # - An optional digit. Some books like "1 Samuel" begin with a single digit.
      # - Any letter, one or more times.
      #  
      # Group 2: Chapters and verses ([^a-zA-Z]+(?![a-zA-Z]))?
      # - Any non-letter character (like digits and punctuation) one or more times.
      # 
      # - Don't capture the last character if it's followed by a letter. Which basically means
      #   don't capture the last character. Usually the last character will be punctuation, like
      #   a comma or semi-colon. We don't need to capture that information. Sometimes it will
      #   be a number, like in "Matt. 1:1, 2 Sam 1:1", where "2" would be the last character.
      #   In this case we want to assume the last character belongs with the next book anyway,
      #   so we shouldn't include it with this one. 
      # 
      # - The last question mark indicates that the chapters/verses are optional. If it's not 
      #   there, then we assume just the first chapter is wanted. So the passage 
      #   "John", is the same as "John 1". This assumption comes
      #   from what BibleGateway does for the same scenario. 
      pattern = /([0-9]?[a-zA-Z]+)([^a-zA-Z]+(?![a-zA-Z]))?/
                                                                      
      # find the books
      passage_slim.scan pattern do |book_name, contents|
        
        # remove all characters from the end util we get to a number.
        # This basically removes any extraneous punctation at the end.        
        contents = contents.gsub(/[^0-9]+$/, "") unless contents.nil?
                
        books << BookReference.new(book_name, contents)     
      end
      
      books.add_error "'#{passage}' does not contain any books" if books.empty?
      books
    end   
    
    
    # Instance Methods
    #----------------------------------------------------------------------------    
    
    # Whether this reference itself is valid. Please note this does not consider the chapters inside
    # the book, just the book itself.
     def valid_reference?
       !name.nil?
     end 
     
     # Parse the raw_content in order to find the chapters in this book.
     def parse_contents
       @chapter_references = ChapterReference.parse_chapters_in_reference self
     end
     
    # Cleans invalid chapter references. After calling this, the chapter_references method will only return good
    # chapter references. You can access the invalid references through chapater_references.invalid_references. 
    # See ReferenceCollection.clean for more information.
    # 
    # If the chain parameter is true (which it is by default) it will also tell valid chapters
    # to clean their verse references. In this case chapter_references.invalid_references will include both bad
    # chapters and bad verses.
    def clean(chain = true)            
      chapter_references.clean(chain)
    end
       
  end
end