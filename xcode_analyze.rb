require 'xcodeproj'
require 'gym'

XCODE_PROJECT_PATH = '/path/to/ios-app/app.xcodeproj/'
XCODE_WORKSPACE_PATH = XCODE_PROJECT_PATH + 'project.xcworkspace'

def target_scheme
  config = FastlaneCore::Configuration.create(Gym::Options.available_options, {:workspace => XCODE_WORKSPACE_PATH})
  project = FastlaneCore::Project.new(config)
  project.select_scheme
  project.options[:scheme]
end

def target_project_setting(target_scheme)
  scheme_file = find_xcschemes(target_scheme)
  xs = Xcodeproj::XCScheme.new(scheme_file)
  target_name = xs.profile_action.buildable_product_runnable.buildable_reference.target_name

  project = Xcodeproj::Project.open(XCODE_PROJECT_PATH)
  project.native_targets.reject{|target| target.name != target_name}.first
end

def find_xcschemes(target_scheme)
  shared_schemes = Dir[File.join(XCODE_PROJECT_PATH, 'xcshareddata', 'xcschemes', '*.xcscheme')].reject do |scheme|
    target_scheme != File.basename(scheme, '.xcscheme')
  end
  user_schemes = Dir[File.join(XCODE_PROJECT_PATH, 'xcuserdata', '*.xcuserdatad', 'xcschemes', '*.xcscheme')].reject do |scheme|
    target_scheme != File.basename(scheme, '.xcscheme')
  end

  shared_schemes.concat(user_schemes).first
end

def target_build_configuration(target_project)
  target_project.build_configuration_list.build_configurations.reject{|conf| conf.name != 'Release'}.first
end

target_project = target_project_setting(target_scheme)
target_build_configuration = target_build_configuration(target_project)

puts 'Product name: ' + target_project.product_name
puts 'Bundle Identifier: ' + target_build_configuration.build_settings['PRODUCT_BUNDLE_IDENTIFIER']
puts 'Provisioning Profile: ' + target_build_configuration.build_settings['PROVISIONING_PROFILE']
