require 'yaml'

module BibleReferenceParser
  
  # This class encapsulates the metadata about a book's name and short name.
  # It also holds info on the number of verses in each chapter. See metadata.yml for more details. 
  class BibleMetadata
    class << self
      # The metadata contents loaded from the yaml file.
      attr_reader :metadata
      
      # Access metadata information for the specified book_name.
      # book_name can either be the full name, or one of the book's
      # abbreviations. For the names and abbreviations recognized,
      # see the metadata.yml file. 
      # 
      # The metadata.yml file indexes book names in lowercase without spaces.
      # The parameter passed in is converted to this format automatically.
      #
      # Examples:
      #     BibleMetadata["Genesis"]
      #     BibleMetadata["gen"]     
      #     BibleMetadata["rev."] 
      #     
      # The returned object is a hash. Example:
      #     {
      #       "name" => "Genesis",
      #       "short" => "Gen.",
      #       "chapter_info" => [31,25,24,26,32,22,24,22,29,32,32...]      
      #     } 
      # 
      # If the book isn't found, "nil" is returned.
      def [](book_name)                       
        # make lowercase and strip out any spaces or periods
        index = book_name.downcase.gsub(/\s*\.*/, "")
        metadata[index]
      end
    end
    
    # Load the metadata on books and chapters from the yaml file
    @metadata = YAML::load_file(File.dirname(__FILE__) + '/metadata.yml') 

  end  
end