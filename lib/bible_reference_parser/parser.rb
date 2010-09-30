# TODO doc me
module BibleReferenceParser  
  
  # TODO doc me 
  def self.parse(passage)
    BookReference.parse_books(passage)
  end

  # See BookReference.parse_books    
  def self.parse_books(passage)
    BookReference.parse_books(passage)
  end

  # See ChapterReference.parse_chapters
  def self.parse_chapters(passage)
    ChapterReference.parse_chapters(passage)
  end

  # See VerseReference.parse_verses
  def self.parse_verses(string)
    VerseReference.parse_verses(string)
  end 
  
end