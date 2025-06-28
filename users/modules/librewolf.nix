{
  config,
  inputs,
  lib,
  ...
}: {
  config = {
    programs.librewolf = {
      enable = true;
      settings = {
        "webgl.disabled" = false;
        "privacy.resistFingerprinting" = false;
        "privacy.clearOnShutdown.history" = false;
        "privacy.clearOnShutdown.cookies" = false;
        "network.cookie.lifetimePolicy" = 0;
        "browser.toolbars.bookmarks.visibility" = "never";
        "browser.startup.page" = 3;
        "extensions.pictureinpicture.enable_picture_in_picture_overrides" = true;
        "browser.newtabpage.activity-stream.showSearch" = false;
        "browser.search.separatePrivateDefault" = false;
        "browser.search.suggest.enabled.private" = true;
        "browser.search.suggest.enabled" = true;
        "browser.urlbar.suggest.searches" = true;
        "general.useragent.compatMode.firefox" = true;
        "browser.uiCustomization.state" = "{\"placements\":{\"widget-overflow-fixed-list\":[],\"unified-extensions-area\":[],\"nav-bar\":[\"back-button\",\"forward-button\",\"stop-reload-button\",\"urlbar-container\",\"save-to-pocket-button\",\"history-panelmenu\",\"bookmarks-menu-button\",\"downloads-button\",\"fxa-toolbar-menu-button\",\"ublock0_raymondhill_net-browser-action\",\"unified-extensions-button\"],\"toolbar-menubar\":[\"menubar-items\"],\"TabsToolbar\":[\"tabbrowser-tabs\",\"new-tab-button\",\"alltabs-button\"],\"PersonalToolbar\":[\"personal-bookmarks\"]},\"seen\":[\"ublock0_raymondhill_net-browser-action\",\"developer-button\"],\"dirtyAreaCache\":[\"unified-extensions-area\",\"nav-bar\",\"toolbar-menubar\",\"TabsToolbar\",\"PersonalToolbar\"],\"currentVersion\":20,\"newElementCount\":3}";
      };
    };
  };
}
