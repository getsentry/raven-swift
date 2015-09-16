Pod::Spec.new do |s|
  s.name         = "RavenSwift"
  s.version      = "0.2.2"
  s.summary      = "swift client for sentry"
  s.homepage     = "https://github.com/getsentry/raven-swift"
  s.license      = "mit"
  s.authors      = "Tommy Mikalsen", "Erik Sargent", "Sean Cheng"
  s.source       = { :git => "https://github.com/getsentry/raven-swift.git", :tag => s.version.to_s }

  s.ios.deployment_target = "8.0"
  s.osx.deployment_target = "10.9"

  s.source_files = "Raven/**/*.{h,m,swift}"
  s.ios.exclude_files = "Raven/Raven-OSX.h"
  s.osx.exclude_files = "Raven/Raven-iOS.h"
end
