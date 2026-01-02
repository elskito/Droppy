cask "droppy" do
  version "1.2.6"
  sha256 "18c8739c883ec30f6bf8420649ea42ce4b16f46d2ed43fe7b4f6cba27408db99"

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
