# Shared examples for classes including the TracksErrors module

module ItTracksErrors  
  shared_examples_for "it tracks errors" do |new_instance|          
    before :each do
      new_instance.clear_errors
    end
    
    describe "initialization" do                   
      it "should set the errors attribute to a kind of array" do
        new_instance.errors.should be_kind_of Array
      end
       
      it "should set the errors attribute to empty" do
        new_instance.errors.should be_empty
      end                                                      
    end
    
    describe "The 'add_error' method" do
      it "should add an error message to the errors collection" do
        new_instance.add_error "invalid"
        new_instance.errors.length.should eql 1
        new_instance.errors.first.should eql "invalid"
      end
    end
    
    describe "the 'clear_errors?' method" do
      it "should erase all errors" do
        new_instance.add_error "invalid"
        new_instance.clear_errors
        new_instance.errors.should be_empty
      end
    end
    
    describe "the 'has_errors?' method" do
      it "should return whether there are any error messages" do
        new_instance.has_errors?.should be_false
        new_instance.add_error "invalid"
        new_instance.has_errors?.should be_true
      end
    end
     
    describe "the 'no_errors?' method" do      
      it "should return whether there are any error messages" do
        new_instance.no_errors?.should be_true
        new_instance.add_error "invalid"
        new_instance.no_errors?.should be_false
      end                
    end
    
    describe "the 'errors' method" do
      before :each do        
        @allows_children = new_instance.respond_to?("children") && new_instance.children
        new_instance.children.clear_errors if @allows_children
      end
      
      it "should not include child errors if include_child_errors is false" do
        new_instance.add_error "invalid"
        new_instance.children.add_error "invalid_child" if @allows_children
        
        errors = new_instance.errors(false)
        errors.count.should eql 1
        errors.first.should eql "invalid"
      end
           
      it "should include child errors if include_child_errors is true" do
        new_instance.add_error "invalid"
        new_instance.children.add_error "invalid_child" if @allows_children
        
        errors = new_instance.errors(true)
        count = @allows_children ? 2 : 1
        errors.count.should eql count
        errors.first.should eql "invalid"
        errors.last.should eql "invalid_child" if @allows_children               
      end
 
      it "should include child errors if include_child_errors isn't specified" do
        new_instance.add_error "invalid"
        new_instance.children.add_error "invalid_child" if @allows_children
        
        errors = new_instance.errors(true)
        count = @allows_children ? 2 : 1
        errors.count.should eql count
        errors.first.should eql "invalid"
        errors.last.should eql "invalid_child" if @allows_children
      end
    end
    
  end     
end