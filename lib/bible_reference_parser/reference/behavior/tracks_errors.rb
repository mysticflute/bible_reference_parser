module BibleReferenceParser
  
  # This module encapsulates shared behavior for classes that keep track of parsing errors. 
  # For example, a BookReference may encounter a parsing error due to a book that doesn't
  # exist. A ChapterReference may have a parsing error because the chapter number isn't valid 
  # for the book it is referencing. 
  module TracksErrors
 
    def initialize(*args, &block) 
      super
   
      # A collection of error messages.                         
      @errors = []
    end
 
    # Add an error message.
    def add_error(message)
      @errors << message
    end 
    
    # Erase all error messages.
    def clear_errors
      @errors = []
    end
   
    # Get the list of error messages. This will include any errors in child references
    # if include_child_errors is true (by default it's true).
    def errors(include_child_errors = true)
      if(include_child_errors && respond_to?("children") && children)
        return @errors + children.errors(true)
      end
      
      @errors
    end

    # Whether any errors occured when parsing.
    def has_errors?
      !errors.empty?
    end

    # Convienence method for the reverse of "has_errors?"
    def no_errors?
      errors.empty?
    end     
  end 
end