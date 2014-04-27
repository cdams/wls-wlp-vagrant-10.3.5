# restart the puppetmaster when changed
module Puppet::Parser::Functions
  newfunction(:list_shared_lib, :type => :rvalue) do |args|
    
    path    = args[0]
    files = [] 
    
    function_notice(["path = #{path}"])
    if File.exists?(path) && File.directory?(path)      
    function_notice(["OK"])
      Dir.entries(path).select { |f| 
        files.push(f)        
        function_notice(["file = #{f}"])
      }
    end
    return files

  end
end