Pod::Spec.new do |s|

  s.name         = "YouTubePlayer"
  s.version      = "0.9.0"
  s.summary      = "YouTubePlayer is a library to fetch video information from the YouTube Data API and play videos using the AVPlayer"

  s.homepage     = "https://github.com/JuanjoArreola/YouTubePlayer"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author       = { "Juanjo Arreola" => "juanjo.arreola@gmail.com" }

  s.platform     = :ios, "8.0"
  s.source       = { :git => "git@github.com:JuanjoArreola/YouTubePlayer.git", :tag => "#{s.version}" }
  s.source_files  = "YouTubePlayer/**/*.swift"

  s.framework  = "AVKit"
  s.requires_arc = true
  s.dependency "Apic"

end
