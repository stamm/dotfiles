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


hs.hotkey.bind({"cmd", "alt", "ctrl"}, "W", function()
  hs.notify.new({title="Hammerspoon", informativeText="Hello World"}):send()
end)


wifiWatcher = nil
homeSSID = "MGTS_GPON5_2477"
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
local applicationHotkeys = {
  c = 'Google Chrome',
  a = 'Alacritty',
}
for key, app in pairs(applicationHotkeys) do
  hs.hotkey.bind(hyper, key, function()
    hs.application.launchOrFocus(app)
  end)
end

hs.alert.show("Config loaded")
