require 'openssl'
require 'plist'

def load_profile_paths
  profiles_path = File.expand_path("~") + "/Library/MobileDevice/Provisioning Profiles/*.mobileprovision"
  Dir[profiles_path]
end

def profile_to_plist(profile_path)
  File.open(profile_path) do |profile|
    asn1 = OpenSSL::ASN1.decode(profile.read)
    plist_str = asn1.value[1].value[0].value[2].value[1].value[0].value
    plist = Plist.parse_xml plist_str.force_encoding('UTF-8')
    plist['Path'] = profile_path
    return plist
  end
end

def adhoc?(profile)
  !profile['Entitlements']['get-task-allow'] && profile['ProvisionsAllDevices'].nil?
end

def installed_certificate?(profile_path)
  profile = profile_to_plist profile_path
  certs = profile['DeveloperCertificates'].map do |cert|
    certificate_str = cert.read
    certificate =  OpenSSL::X509::Certificate.new certificate_str
    id = OpenSSL::Digest::SHA1.new(certificate.to_der).to_s.upcase!
    installed_distribution_certificate_ids.include?(id)
  end
  certs.include?(true)
end

def installed_distribution_certificate_ids
  certificates = installed_certificates()
  ids = []
  certificates.each do |current|
    next unless current.match(/iPhone Distribution:/)
    begin
      (ids << current.match(/.*\) (.*) \".*/)[1])
    rescue
      # the last line does not match
    end
  end

  ids
end

def installed_certificates
  available = `security find-identity -v -p codesigning`
  certificates = []
  available.split("\n").each do |current|
    next if current.include? "REVOKED"
    certificates << current
  end

  certificates
end

def codesigning_identity(profile_path)
  profile = profile_to_plist profile_path
  identity = nil

  profile['DeveloperCertificates'].each do |cert|
    certificate_str = cert.read
    certificate =  OpenSSL::X509::Certificate.new certificate_str
    id = OpenSSL::Digest::SHA1.new(certificate.to_der).to_s.upcase!

    available = `security find-identity -v -p codesigning`
    available.split("\n").each do |current|
      next if current.include? "REVOKED"
      begin
        search = current.match(/.*\) (.*) \"(.*)\"/)
        identity = search[2] if id == search[1]
      rescue
      end
    end
  end

  identity
end

def profiles
  load_profile_paths.map{|path| profile_to_plist(path)}
end

profiles.each do |profile|
  puts "UUID: #{profile['UUID']}"
  puts "ExpirationDate: #{profile['ExpirationDate']}"
  puts "Application identifier: #{profile['Entitlements']['application-identifier']}" if profile['Entitlements']
  puts "Team name: #{profile['TeamName']}"
  puts "Codesigning identity : #{codesigning_identity(profile['Path'])}"
  puts "Adhoc? : #{adhoc?(profile)}"
  puts "Installed certificate? : #{installed_certificate?(profile['Path'])}"
end
