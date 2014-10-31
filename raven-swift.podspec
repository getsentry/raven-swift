Pod::Spec.new do |s|
  s.name                = "raven-swift"
  s.version             = "0.1.0"
  s.summary             = "A client for Sentry (getsentry.com)."
  s.description         = <<-DESC
                             Shit happens — Be on top of it.
                             Sentry gives you insight into the errors that affect your customers.
                             DESC

  s.homepage            = "http://getsentry.com"
  s.license             = { :type => "MIT", :file => "LICENSE" }
  s.author              = "Tommy Mikalsen"
  s.social_media_url    = "http://github.com/timorzadir"
  s.source              = { :git => "https://github.com/getsentry/raven-swift.git", :tag => s.version.to_s }
  s.source_files        = ['Raven']
  s.requires_arc        = true
end
