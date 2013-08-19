# unless defined?(Motion::Project::Config)
#   raise "This file must be required within a RubyMotion project Rakefile."
# end

if defined? Motion
	Motion::Project::App.setup do |app|

		Dir.glob(File.join(File.dirname(__FILE__), 'bblmotionkit/*.rb')).each do |file|
			app.files.unshift(file)
		end


		# TODO frameworks, vendor projects
	end
end