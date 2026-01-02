cask "droppy" do
  version "1.2.1"
  sha256 "70509b45f1009205291d5dbb7cf5d95977777602864a5082d3affb80326a557d"

  url "https://raw.githubusercontent.com/iordv/Droppy/main/Droppy.dmg"
  name "Droppy"
  desc "Drag and drop file shelf for macOS"
  homepage "https://github.com/iordv/Droppy"

  app "Droppy.app"

  zap trash: [
    "~/Library/Application Support/Droppy",
    "~/Library/Preferences/iordv.Droppy.plist",
  ]
end
