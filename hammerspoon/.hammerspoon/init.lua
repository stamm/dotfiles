function reloadConfig(files)
  doReload = false
  for _,file in pairs(files) do
    if file:sub(-4) == ".lua" then
      doReload = true
    end
  end
  if doReload then
    hs.reload()
  end
end
myWatcher = hs.pathwatcher.new(os.getenv("HOME") .. "/.hammerspoon/", reloadConfig):start()


function handle(location)
  if location == "home" then
    hs.alert.show("home")
  end
end


print(hs.inspect(hs.network.interfaceDetails()["IPv4"].Addresses))

hs.hotkey.bind({"cmd", "alt", "ctrl"}, "W", function()
  hs.notify.new({title="Hammerspoon", informativeText="Hello World"}):send()
end)

for i, eth in pairs(hs.network.interfaces()) do
  if eth == "en7" then
    -- hs.alert.show("en7")
    if not hs.network.interfaceDetails(eth) == nil then
      for i, net in pairs(hs.network.interfaceDetails(eth)["IPv4"].Addresses) do
	if net == "192.168.120.13" then
	  -- hs.alert.show("home net")
	end
      end
    end
  end
end


wifiWatcher = nil
homeSSID = "az5"
dachaSSID = "Keenetic-7791"

lastSSID = hs.wifi.currentNetwork()
function ssidChangedCallback()
  newSSID = hs.wifi.currentNetwork()
  if newSSID == homeSSID and lastSSID ~= homeSSID then
    -- We just joined our home WiFi network
    hs.alert.show("Home")
  elseif newSSID ~= homeSSID and lastSSID == homeSSID then
    -- We just departed our home WiFi network
    if newSSID == dachaSSID then
      hs.alert.show("Dacha")
    else
      hs.alert.show("Not home")
    end
  end

  lastSSID = newSSID
end
wifiWatcher = hs.wifi.watcher.new(ssidChangedCallback)
wifiWatcher:start()


homeDisplays = {}
homeDisplays[684386818] = 1
function screenChangedCallback()
  for i, screen in ipairs(hs.screen.allScreens()) do
    if homeDisplays[screen:id()] then
      handle("home")
    end
  end
end
screenWatcher = hs.screen.watcher.new(screenChangedCallback)
screenWatcher:start()
screenChangedCallback()

local hyper = { "cmd", "alt", "ctrl", "shift" }
hs.hotkey.bind(hyper, "Y", hs.toggleConsole)
local applicationHotkeys = {
  f = 'Firefox',
  a = 'Alacritty',
  d = 'Discord',
  t = 'Telegram',
  m = 'Mail',
  c = 'Calendar',
  b = 'Bitwarden',
  v = 'VSCodium',
}
for key, app in pairs(applicationHotkeys) do
  hs.hotkey.bind(hyper, key, function()
    if not hs.application.launchOrFocus(app) then
      hs.alert.show("err")
    end
  end)
end


hs.hotkey.bind({}, "F16", function()
  hs.keycodes.setLayout("English - Ilya Birman Typography")
end)

hs.hotkey.bind({}, "F17", function()
  hs.keycodes.setLayout("Russian - Ilya Birman Typography")
end)

-- hs.grid.show()
hs.alert.show("Config loaded")
