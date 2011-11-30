# This module contains some file management related methods used in tasks
module Ubiquo
  module Tasks 
    module Files
  
      # Place the fixtures that are inside plugins into a temporal folder to be used
      # in ubiquo tests
      def install_ubiquo_fixtures
        copy_dir(Dir[Rails.root.join('vendor', 'plugins', 'ubiquo**', 'test', 'fixtures')], "/tmp/ubiquo_fixtures", :force => true, :link => true)    
      end
  
      # Options accepted:
      #   force:    copy files even if target exists. Defaults to false
      #   verbose:  print results. Defaults to false
      #   link:     use softlinks instead of cp. Defaults to false
      def copy_dir(from, path = "/", options = {})
        force = options[:force]
        verbose = false || options[:verbose]
        rails_target = File.join(Rails.root, path)
        FileUtils.mkdir_p(rails_target, :verbose => verbose) unless File.exists?(rails_target)
        [from].flatten.each do |f|
          files = Dir.glob(File.join(f, "*"))
          if options[:link]
            begin
              FileUtils.ln_s(files, rails_target, :verbose => verbose, :force => force)
            rescue Errno::EEXIST
            end
          else
            # refactorable
            files.each do |file|
              file_name = File.basename(file)
              if File.directory?(file)
                copy_dir(file, File.join(path, file_name), options)
              else
                FileUtils.cp(file, rails_target, :verbose => verbose) if force || !File.exists?(File.join(rails_target, file_name))
              end
            end
          end
        end
      end
    end
  end
end