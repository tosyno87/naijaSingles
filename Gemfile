# Gemfile for NaijaSingles - African Diaspora Dating App
source "https://rubygems.org"

# Fastlane for iOS and Android deployment automation
gem "fastlane"

# Ruby version
ruby ">= 2.7.0"

# Additional gems for enhanced functionality
gem "cocoapods", ">= 1.15.0" # For iOS dependency management (updated to support activesupport 6.x)
gem "xcode-install" # For Xcode version management

# Security: Pin activesupport to patched version to fix CVE-2023-38037 and CVE-2023-28120
gem "activesupport", ">= 6.1.7.5"

# Security: Pin faraday to fix SSRF via protocol-relative URL host override (Dependabot #9)
gem "faraday", ">= 1.10.5", "< 2.0"

# Development gems
group :development do
  gem "rubocop" # Ruby code style checker
  gem "rubocop-performance" # Performance-focused linting
end