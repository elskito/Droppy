cask "droppy" do
  version "2.0.2"
  sha256 "d991dad4b9a2e317bc1cd0888d8bc0866001af3ad751760c82ee88ae715715da"

  url "https://raw.githubusercontent.com/iordv/Droppy/main/Droppy-2.0.2.dmg"
  name "Droppy"
  desc "Drag and drop file shelf for macOS"
  homepage "https://github.com/iordv/Droppy"

  app "Droppy.app"

  zap trash: [
    "~/Library/Application Support/Droppy",
    "~/Library/Preferences/iordv.Droppy.plist",
  ]
end
