# restart the puppetmaster when changed
module Puppet::Parser::Functions
  newfunction(:file_exists, :type => :rvalue) do |args|
    
    path    = args[0]
    files = [] 
    
    if File.exists?(path)     
      return true
    end
    return false

  end
end