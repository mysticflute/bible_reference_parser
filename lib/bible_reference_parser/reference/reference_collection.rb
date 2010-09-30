module BibleReferenceParser 
   
  # This class is used to hold collections of reference objects.
  # It functions similar to an array, augmented with information about whether
  # any parsing errors occured in the items it contains.
  # 
  # A ReferenceCollection is returned from the following methods:
  # - All BibleReferenceParser.parse methods
  # - BookReference.parse_books
  # - ChapterReference.parse_chapters
  # - VerseReference.parse_verses
  # 
  # Also, child references are ReferenceCollection objects. For example:
  #
  #     books = BibleReferenceParser.parse "Genesis 1:1"
  #     books.first.chapter_references # => a reference collection
  #     books.first.children # => an alias for chapter_references, so also a reference collection
  #     books.first.chapter_references.first.verse_references # => another reference collection
  # 
  # ReferenceCollections let you quickly see all the errors in the items it contains. Example:
  # 
  #     books = BibleReferenceParser.parse("Genthesis 1:1-10, Matthew 1:5, Rev. 5000") # books is a ReferenceCollection
  #     books.length # => 3
  #     books.has_errors? # => true
  #     books.no_errors? # => false
  #     books.errors.length # => 2
  #     books.errors # => ["The book 'Genthesis' could not be found", "Chapter '5000' does not exist for the book Revelation"]
  #     bad_books = books.clean
  #     books.length # => 1 (Matthew 1:5)
  #     books.invalid_references.length # => 2
  # 
  # After calling the clean method, bad references are move to the invalid_references field. Please note
  # that a reference will still be left in the collection as long as itself is valid. So a valid book could possibly only contain 
  # invalid chapters:
  # 
  #     books = BibleReferenceParser.parse("Genesis 51") # genesis is valid, but chapter 51 isn't
  #     books.clean
  #     books.length # => 1 (still contains the reference to Genesis)
  #     books.first.has_errors? # => true
  #     books.first.chapter_references.length # => 0
  #     books.first.chapter_references.invalid_references.length # => 1 
  #     books.invalid_references.length # => 1 (returns the same as above, just less explicit)
  #     books.errors # => ["Chapter '51' does not exist for the book Genesis"] 
  # 
  # XXX next we can add a method for sorting items in the collection.

  class ReferenceCollection
    include TracksErrors
    
    attr_reader :references, :invalid_references
    
    # Initialization
    #----------------------------------------------------------------------------
    
    def initialize(initial_references = [], initial_invalid_references = [])
      super 
                      
      # Array of reference objects this collection contains
      @references = initial_references
                  
      # Holds references that are invalid. The "clean" method finds all invalid
      # references and moves them to this collection.
      @invalid_references = initial_invalid_references
    end       
    
    
    # Instance Methods
    #----------------------------------------------------------------------------
    
    # Get all the errors in this reference collection. 
    def errors(include_child_errors = true)
      # start with errors added directly to this reference collection
      all_errors = super(include_child_errors)
      
      # include the errors from invalid references
      @invalid_references.each do |reference|
        all_errors += reference.errors(include_child_errors)
      end
      
      # include the errors from references
      @references.each do |reference|
        all_errors += reference.errors(include_child_errors)
      end

      all_errors.uniq      
    end
    
    # Moves invalid references into the special "invalid_references" collection. A reference is valid 
    # if it's "valid_reference?" method returns true. This is useful if you want to loop through the valid
    # references only, and deal with the invalid ones separately:
    # 
    #     books = BibleReferenceParser.parse("Matthew 1:1, Mark 1:1, Lkue 1:1")
    #     books.length # => 3 (all three references)
    #     books.clean
    #     books.length # => 2 ("Lkue" is now in the invalid_references collection)
    #     books.each do |book| ... # => loop through just the good references
    #     books.invalid_refernces.each do |invalid| ... # now deal with the bad ones    
    # 
    # The chain paremeter indicates whether child references should also be cleaned. For example, if you
    # have a collection of book references, if chain is true it will also call clean on the chapter and 
    # verse references. Chain is true by default.
    # 
    # Please note that a valid reference may not actually contain valid references. For example:
    # 
    #     books = BibleReferenceParser.parse("Genesis 51") # genesis is valid, but chapter 51 isn't
    #     books.chapter_references.length # => 1    
    #     books.clean
    #     books.chapter_references.length # => 0
    #     books.chapter_references.invalid_references.length # => 1
    # 
    #   
    def clean(chain = true)
      removed = []
      removed_through_chain = []
      
      @references.each do |reference|
        if reference.valid_reference?
          removed_through_chain += reference.clean if chain
        else
          removed << reference
        end
      end
      
      @references -= removed
      
      all_removed = (removed + removed_through_chain)
      @invalid_references += all_removed
      
      all_removed
    end    
    
    
    # Delegate Methods
    #----------------------------------------------------------------------------
    
    # Accepts either an Array or ReferenceCollection
    def +(collection)
      new_references = collection.kind_of?(ReferenceCollection) ? collection.references : collection
      combined_references = references + new_references
      ReferenceCollection.new(combined_references, invalid_references)
    end      
    
    # Accepts either an Array or ReferenceCollection
    def -(collection)
      new_references = collection.kind_of?(ReferenceCollection) ? collection.references : collection
      combined_references = references - new_references
      ReferenceCollection.new(combined_references, invalid_references)
    end
    
    def [](index) 
      references[index]
    end

    def each(*args, &block)
       references.each(*args, &block)
    end
 
    def <<(reference)
      references << reference
    end
    
    def length
      references.length
    end
    
    def first
      references.first
    end
    
    def last 
      references.last
    end
    
    def empty?
      references.empty?
    end

  end           
end