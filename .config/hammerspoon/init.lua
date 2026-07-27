
-- Caps Lock -> F18 (hidutil mapping resets at reboot; re-applied here since
-- Hammerspoon launches at login)
hs.execute([[/usr/bin/hidutil property --set '{"UserKeyMapping":[{"HIDKeyboardModifierMappingSrc":0x700000039,"HIDKeyboardModifierMappingDst":0x70000006D}]}']])

-- F18 held = hyper layer
local hyper = hs.hotkey.modal.new()
hs.hotkey.bind({}, "f18",
    function() hyper:enter() end,
    function() hyper:exit() end)

-- Caps+letter app switching
local apps = {
    t = "iTerm",
    s = "Safari",
    c = "Claude",
    g = "Things3",
    p = "Preview",
    m = "Messages",
    l = "Mail",
    u = "Music",
    n = "Notes",
}
for key, app in pairs(apps) do
    hyper:bind({}, key, function() hs.application.launchOrFocus(app) end)
end

-- Edit any text field in emacsclient, then paste the result back.
-- Bind: ⌘⌥E. Finish editing in Emacs with C-x # (server-edit).
-- Requires the Emacs server: (server-start) in init.el, or `emacs --daemon`.

local emacsclient = "/opt/homebrew/bin/emacsclient" -- `which emacsclient` to check;
                                                    -- /usr/local/bin on Intel Macs
local tmpfile = os.getenv("HOME") .. "/.hs-edit-buffer.md" -- .md gets you markdown-mode

hyper:bind({}, "e", function()
  local app = hs.application.frontmostApplication()
  local oldClipboard = hs.pasteboard.getContents()

  -- Grab whatever is in the focused field
  hs.eventtap.keyStroke({"cmd"}, "a")
  hs.eventtap.keyStroke({"cmd"}, "c")

  hs.timer.doAfter(0.2, function()
    local text = hs.pasteboard.getContents() or ""
    local f = io.open(tmpfile, "w")
    f:write(text)
    f:close()

    -- Without -n, emacsclient blocks until you hit C-x # in Emacs
    local task = hs.task.new(emacsclient, function(exitCode)
      if exitCode ~= 0 then
        hs.alert.show("emacsclient failed — is the Emacs server running?")
        return
      end
      local f2 = io.open(tmpfile, "r")
      local edited = f2:read("*a")
      f2:close()

      hs.pasteboard.setContents(edited)
      app:activate()
      hs.timer.doAfter(0.25, function()
        hs.eventtap.keyStroke({"cmd"}, "a")
        hs.eventtap.keyStroke({"cmd"}, "v")
        -- restore your real clipboard after the paste lands
        if oldClipboard then
          hs.timer.doAfter(0.5, function()
            hs.pasteboard.setContents(oldClipboard)
          end)
        end
      end)
    end, {"-c", tmpfile}) -- -c opens a new GUI frame; drop it to reuse an existing one
    task:start()
  end)
end)
