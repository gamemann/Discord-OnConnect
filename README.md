# Discord On Connect

## Description
A quick plugin I wrote for SourceMod. When a client joins the game, it will open an MOTD window with a Discord invite link or anything else you want. Comes with many features. Supports menus, cookies, and more.

## ConVars
* `sm_doc_enabled` => Enables plugin (Default: 1).
* `sm_doc_title` => MOTD window's title. (Default: "Join our Discord server and get free rewards!").
* `sm_doc_link` => Discord invite link. (Default: "https://discord.gg/MnPD6BG").
* `sm_doc_menu` => Show a menu stating to join the server on connect? (Default: 1).
* `sm_doc_notify` => Notify the client that we invited them to our Discord server when `sm_doc_menu` is set to 0. (Default: 1).
* `sm_doc_prevent_multiple` => Prevent more than one invite per user. (Default: 1).
* `sm_doc_goto` => Go to another URL after opening Discord link two seconds later (silently). (Default: 1).
* `sm_doc_goto_url` => URL to go to if 'sm_doc_goto' is set to 1. (Default: "https://GFLClan.com/").
* `sm_doc_hook` => Hook to use when presenting menu. 1 = Hook->player_initial_spawn. 2 = OnClientPostAdminCheck. (Default: 2).
* `sm_doc_wait_time` => Wait time when using '2' as `sm_doc_hook`. (Default: 10.0).

## Credits
* [Christian Deacon](https://www.linkedin.com/in/christian-deacon-902042186/)