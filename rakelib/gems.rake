require "rubygems/specification"
require "rubygems/commands/install_command"
require "logstash/JRUBY-PR1448" if RUBY_PLATFORM == "java" && Gem.win_platform?

ENV["GEM_HOME"] = ENV["GEM_PATH"] = Gem.paths = "build/bootstrap/"

file "build/bootstrap" => "build" do |task,args|
  mkdir task.name
end

namespace "gem" do
  task "require",  :name, :requirement, :target do |task, args|
    name, requirement, target = args[:name], args[:requirement], args[:target]
    begin
      gem name, requirement
    rescue Gem::LoadError => e
      #puts "Failed to load #{name} #{requirement}: #{e}"
      Rake::Task["gem:install"].invoke(name, requirement, target)
    end
    task.reenable # Allow this task to be run again
  end

  task "install", [:name, :requirement, :target] =>  ["build/bootstrap"] do |task, args|
    name, requirement, target = args[:name], args[:requirement], args[:target]
    puts "[bootstrap] Fetching and installing gem: #{name} (#{requirement})"

    installer = Gem::Commands::InstallCommand.new
    installer.options[:generate_rdoc] = false
    installer.options[:generate_ri] = false
    installer.options[:version] = requirement
    installer.options[:args] = [name]
    installer.options[:install_dir] = target

    # ruby 2.0.0 / rubygems 2.x; disable documentation generation
    installer.options[:document] = []
    begin
      installer.execute
    rescue Gem::SystemExitException => e
      if e.exit_code != 0
        puts "Installation of #{name} failed"
        raise
      end
    end

    task.reenable # Allow this task to be run again
  end # task "install"
end # namespace "gem"
