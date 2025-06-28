{
  config,
  inputs,
  lib,
  ...
}: {
  config = {
    dconf.settings = {
      "org/gnome/settings-daemon/plugins/media-keys" = {
        #Accessibility
        decrease-text-size = []; #Decrease text size
        toggle-contrast = []; #High contrast on or off
        increase-text-size = []; #Increase text size
        on-screen-keyboard = []; #Turn on-screen keyboard on or off
        screenreader = []; #Turn screen reader on or off
        magnifier = []; #Turn zoom on or off
        magnifier-zoom-in = []; #Zoom in
        magnifier-zoom-out = []; #Zoom out

        #Launchers
        home = []; #Home folder
        calculator = []; #Launch calculator
        email = []; #Launch email client
        help = []; #Launch help browser
        www = []; #Launch web browser
        search = []; #Search
        control-center = []; #Settings

        #Sound and Media
        eject = []; #Eject
        media = []; #Launch media player
        mic-mute = []; #Microphone mute/unmute
        next = []; #Next track
        pause = []; #Pause playback
        play = []; #Play (or play/pause)
        previous = []; #Previous track
        stop = []; #Stop playback
        volume-down = []; #Volume down
        volume-mute = []; #Volume mute/unmute
        volume-up = []; #Volume up

        #System
        screensaver = ["<shift><super>backspace"]; #Lock Screen
        logout = []; #Log out
      };

      "org/gnome/shell/keybindings" = {
        #Screenshots
        show-screen-recording-ui = []; #Record a screencast interactively
        screenshot = []; #Take a screenshot
        show-screenshot-ui = ["<shift><super>s"]; #Take a screenshot interactively
        screenshot-window = ["<shift><control><super>s"]; #Take a screenshot of a window

        #System
        focus-active-notifications = []; #Focus the active notification
        toggle-quick-settings = []; #Open the quick settings menu
        toggle-application-view = []; #Show all apps
        toggle-message-tray = []; #Show the notification list
        toggle-overview = []; #Show the overview
      };

      "org/gnome/desktop/wm/keybindings" = {
        #Navigation
        show-desktop = []; #Hide all normal windows
        move-to-monitor-down = []; #Move window one monitor down
        move-to-monitor-left = []; #Move window one monitor to the left
        move-to-monitor-right = []; #Move window one monitor to the right
        move-to-monitor-up = []; #Move window one monitor up
        move-to-workspace-left = []; #Move window one workspace to the left
        move-to-workspace-right = []; #Move window one workspace to the right
        move-to--workspace-last = []; #Move window to the last workspace
        move-to-workspace-1 = []; #Move window to workspace 1
        move-to-workspace-2 = []; #Move window to workspace 2
        move-to-workspace-3 = []; #Move window to workspace 3
        move-to-workspace-4 = []; #Move window to workspace 4
        switch-applications = []; #Switch applications
        switch-applications-backward = [];
        switch-panels = []; #Switch system controls
        switch-panels-backward = [];
        cycle-panels = []; #Switch system controls directly
        cycle-panels-backward = [];
        switch-to-workspace-last = []; #Switch to last workspace
        switch-to-workspace-1 = []; #Switch to workspace 1
        switch-to-workspace-2 = []; #Switch to workspace 2
        switch-to-workspace-3 = []; #Switch to workspace 3
        switch-to-workspace-4 = []; #Switch to workspace 4
        switch-to-workspace-left = []; #Switch to workspace on the left
        switch-to-workspace-right = []; #Switch to workspace on the right
        switch-windows = []; #Switch windows
        switch-windows-backward = [];
        cycle-windows = []; #Switch windows directly
        cycle-windows-backward = [];
        cycle-group = []; #Switch windows of an app directly
        cycle-group-backward = [];
        switch-group = []; #Switch windows of an application
        switch-group-backward = [];

        #System
        panel-run-dialog = []; #Show the run command prompt

        #Typing
        switch-input-source = []; #Switch to next input source
        switch-input-source-backward = []; #Switch to previous input source

        #Windows
        activate-window-menu = []; #Activate the window menu
        close = []; #Close window
        minimize = []; #Hide window
        lower = []; #Lower window below other windows
        maximize = []; #Maximize window
        maximize-horizontally = []; #Maximize window horizontally
        maximize-vertically = []; #Maximize window vertically
        begin-move = []; #Move window
        raise = []; #Raise window above other windows
        raise-or-lower = []; #Raise window if covered, otherwise lower it
        begin-resize = []; #Resize window
        unmaximize = []; #Restore window
        toggle-fullscreen = []; #Toggle fullscreen mode
        toggle-maximized = []; #Toggle maximization state
        toggle-on-all-workspace = []; #Toggle window on all workspaces or one
      };

      "org/gnome/mutter/wayland/keybindings" = {
        #System
        restore-shortcuts = []; #Restore the keyboard shortcuts

        #Windows
        toggle-tiled-left = []; #View split on left
        toggle-tiled-right = []; #View split on right
      };

      "org/gnome/shell/extensions/paperwm/keybindings" = {
        #PaperWM Windows
        new-window = ["<super>n"]; #Open new window
        close-window = ["<super>q"]; #Close the active window
        switch-next = []; #Switch to the next window
        switch-previous = []; #Switch to the previous window
        switch-left = ["<super>h"]; #Switch to the left window
        switch-right = ["<super>l"]; #Switch to the right window
        switch-up = ["<super>k"]; #Switch to the above window
        switch-down = ["<super>j"]; #Switch to the below window
        switch-first = ["<shift><super>i"]; #Switch to the first window
        switch-last = ["<shift><super>o"]; #Switch to the last window
        live-alt-tab = []; #Switch to previously active window
        live-alt-tab-backward = []; #Switch to previously active window, backward order
        switch-focus-mode = []; #Switch between Window Focus Modes
        move-left = ["<shift><super>h"]; #Move the active window to the left
        move-right = ["<shift><super>l"]; #Move the active window to the right
        move-up = ["<shift><super>k"]; #Move the active window up
        move-down = ["<shift><super>j"]; #Move the active window down
        slurp-in = ["<super>i"]; #Consume the window to the right into the active column
        barf-out = ["<super>o"]; #Expel the bottom window into its own column
        center-horizontally = []; #Center window horizontally
        paper-toggle-fullscreen = ["<super>f"]; #Toggle fullscreen
        toggle-maximize-width = []; #Maximize the width of the active window
        resize-h-inc = []; #Increment window height
        resize-h-dec = []; #Decrement window height
        resize-w-inc = []; #Increment window width
        resize-w-dec = []; #Decrement window width
        cycle-width = ["<super>period"]; #Cycle through useful window widths
        cycle-width-backwards = ["<super>comma"]; #Cycle through useful window widths backwards
        cycle-height = ["<shift><super>greater"]; #Cycle through useful window heights
        cycle-height-backwards = ["<shift><super>comma"]; #Cycle through useful window heights backwards
        take-window = ["<super>g"]; #Take the window, dropping it when finished navigating

        #PaperWM Workspaces
        previous-workspace = []; #Switch to previously active workspace
        previous-workspace-backward = []; #Switch to the previously active workspace, backward order
        move-previous-workspace = []; #Move the active window to the previously active workspace
        move-previous-workspace-backward = []; #Move the active window to the previously active workspace, backward order
        switch-up-workspace = ["<super>u"]; #Switch to workspace above (ws only from current monitor)
        switch-down-workspace = ["<super>m"]; #Switch to the workspace below (ws only from current monitor)
        switch-up-workspace-from-all-monitors = []; #Switch to workspace above (ws from all monitors)
        switch-down-workspace-from-all-monitors = []; #Switch to workspace below (ws from all monitors)
        move-up-workspace = ["<shift><super>u"]; #Move window one workspace up
        move-down-workspace = ["<shift><super>m"]; #Move window one workspace down

        #PaperWM Monitors
        switch-monitor-right = ["<shift><control><super>l"]; #Switch to the right monitor
        switch-monitor-left = ["<shift><control><super>h"]; #Switch to the left monitor
        switch-monitor-above = ["<shift><control><super>k"]; #Switch to the above monitor
        switch-monitor-below = ["<shift><control><super>j"]; #Switch to the below monitor
        swap-monitor-right = []; #Swap workspace with monitor to the right
        swap-monitor-left = []; #Swap workspace with monitor to the left
        swap-monitor-above = []; #Swap workspace with monitor above
        swap-monitor-below = []; #Swap workspace with monitor below
        move-monitor-right = ["<control><super>l"]; #Move the active window to the right monitor
        move-monitor-left = ["<control><super>h"]; #Move the active window to the left monitor
        move-monitor-above = ["<control><super>k"]; #Move the active window to the above monitor
        move-monitor-below = ["<control><super>j"]; #Move the active window to the below monitor

        #Scratch layer
        toggle-scratch-layer = []; #Toggles the floating scratch layer
        toggle-scratch = ["<super>s"]; #Attach/detach the active window into the scratch layer
        toggle-scratch-window = []; #Toggle the most recent scratch window
      };
    };
  };
}
