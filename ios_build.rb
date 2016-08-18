require 'gym'

EXPORT_METHOD = 'ad-hoc' # ad-hoc or enterprise
WORKSPACE = '/path/to/ios-app/app.xcodeproj' # cocoapodsを使ってる場合はapp.xcworkspace
CONFIGURATION = 'Release'
SCHEME = 'target_scheme'
CODESIGNING_IDENTITY = 'iPhone Distribution: HOGE (xxxxxxxxx)'

def build
  values = {
      export_method: EXPORT_METHOD,
      workspace: WORKSPACE,
      configuration: CONFIGURATION,
      scheme: SCHEME,
      codesigning_identity: CODESIGNING_IDENTITY
  }
  v = FastlaneCore::Configuration.create(Gym::Options.available_options, values)

  File.expand_path(Gym::Manager.new.work(v))
end

puts "Output ipa path: #{build}"
