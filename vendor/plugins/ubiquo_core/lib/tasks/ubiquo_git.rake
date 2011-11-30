namespace :ubiquo do

  namespace :foreach do
    GIT_TASKS = { 
      :pull => 'git pull',
      :status => 'git status',
      :checkout => 'git checkout'
    }
    
    GIT_TASKS.each do | name, command |
      eval <<-CODE
        desc "Runs #{command} on each plugin dir"
        task :#{name} do
          Rake::Task['ubiquo:foreach'].invoke('#{command}')
        end
      CODE
    end
    
  end
  
end
