class Free < Widget
  self.allowed_options = [:content]
  
  validates_presence_of :content

end
