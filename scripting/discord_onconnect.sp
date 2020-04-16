#include <sourcemod>
#include <sdktools>
#include <clientprefs>

public Plugin myinfo =
{
    name = "Discord On Connect",
    author = "Christian Deacon",
    description = "Joins Discord on player join.",
    version = "1.0.0",
    url = "GFLClan.com"
};

// ConVars.
ConVar g_cvEnabled = null;
ConVar g_cvTitle = null;
ConVar g_cvLink = null;
ConVar g_cvMenu = null;
ConVar g_cvNotify = null;
ConVar g_cvPreventRejoin = null;
ConVar g_cvGoTo = null;
ConVar g_cvGoToURL = null;
ConVar g_cvHook = null;
ConVar g_cvWaitTime = null;

// ConVar values.
bool g_bEnabled;
char g_sTitle[256];
char g_sLink[256];
bool g_bMenu;
bool g_bNotify;
bool g_bPreventRejoin;
bool g_bGoTo;
char g_sGoToURL[256];
int g_iHook;
float g_fWaitTime;

// Cookies.
Handle g_cSent;
Handle g_cJoined;

public void OnPluginStart()
{
    // Initialize ConVars.
    g_cvEnabled = CreateConVar("sm_doc_enabled", "1", "Enable plugin?");
    g_cvTitle = CreateConVar("sm_doc_title", "Join our Discord server and get free rewards!", "MOTD window's title.");
    g_cvLink = CreateConVar("sm_doc_link", "https://discord.gg/MnPD6BG", "Discord invite link.");
    g_cvMenu = CreateConVar("sm_doc_menu", "1", "Show a menu stating to join the server on connect?");
    g_cvNotify = CreateConVar("sm_doc_notify", "1", "Notify the client that we invited them to our Discord server when 'sm_doc_menu' is set to 0.");
    g_cvPreventRejoin = CreateConVar("sm_doc_prevent_multiple", "1", "Prevent more than one invite per user.");
    g_cvGoTo = CreateConVar("sm_doc_goto", "0", "Go to another URL after opening Discord link two seconds later.");
    g_cvGoToURL = CreateConVar("sm_doc_goto_url", "https://GFLClan.com/", "URL to go to if 'sm_doc_goto' is set to 1.");
    g_cvHook = CreateConVar("sm_doc_hook", "2", "Hook to use when presenting menu. 1 = Hook->player_initial_spawn. 2 = OnClientPostAdminCheck.");
    g_cvWaitTime = CreateConVar("sm_doc_wait_time", "10.0", "Wait time when using '2' as 'sm_doc_hook'.");

    // ConVar changes.
    HookConVarChange(g_cvEnabled, ConVarChanged);
    HookConVarChange(g_cvTitle, ConVarChanged);
    HookConVarChange(g_cvLink, ConVarChanged);
    HookConVarChange(g_cvMenu, ConVarChanged);
    HookConVarChange(g_cvNotify, ConVarChanged);
    HookConVarChange(g_cvPreventRejoin, ConVarChanged);
    HookConVarChange(g_cvGoTo, ConVarChanged);
    HookConVarChange(g_cvGoToURL, ConVarChanged);
    HookConVarChange(g_cvWaitTime, ConVarChanged);

    // Initialize Cookies.
    g_cSent = RegClientCookie("doc_sent", "DOC Sent", CookieAccess_Protected);
    g_cJoined = RegClientCookie("doc_joined", "DOC Joined", CookieAccess_Protected);

    // Hook player spawn event.
    HookEvent("player_initial_spawn", Event_PlayerSpawn);

    // Execute config.
    AutoExecConfig(true, "sm_doc");
}

public void OnConfigsExecuted()
{
    // Assign ConVar values.
    g_bEnabled = g_cvEnabled.BoolValue;
    GetConVarString(g_cvTitle, g_sTitle, sizeof(g_sTitle));
    GetConVarString(g_cvLink, g_sLink, sizeof(g_sLink));
    g_bMenu = g_cvMenu.BoolValue;
    g_bNotify = g_cvNotify.BoolValue;
    g_bPreventRejoin = g_cvPreventRejoin.BoolValue;
    g_bGoTo = g_cvGoTo.BoolValue;
    GetConVarString(g_cvGoToURL, g_sGoToURL, sizeof(g_sGoToURL));
    g_iHook = g_cvHook.IntValue;
    g_fWaitTime = g_cvWaitTime.FloatValue;
}

public void ConVarChanged(ConVar cv, const char[] oldV, const char[] newV)
{
    OnConfigsExecuted();
}

public void ShowURL(int iClient, const char[] sURL)
{
    if (!IsClientInGame(iClient))
    {
        return;
    }

    KeyValues kv = CreateKeyValues("motd");

    kv.SetNum("customsvr", 1);
    kv.SetNum("type", MOTDPANEL_TYPE_URL);
    kv.SetString("title", g_sTitle);
    kv.SetString("msg", sURL);

    ShowVGUIPanel(iClient, "info", kv, false);

    delete kv;
}

public Action GoToTimer(Handle timer, any iClient)
{
    if (!IsClientInGame(iClient))
    {
        return Plugin_Continue;
    }

    ShowURL(iClient, g_sGoToURL);

    return Plugin_Continue;
}

public int ConnectMenu(Menu menu, MenuAction action, int param1, int param2)
{
    // Check menu action.
    if (action == MenuAction_Select)
    {
        // Check if menu item is "Yes!".
        if (param2 == 0)
        {
            // Display MOTD window to client.
            ShowURL(param1, g_sLink);

            // Check if we should go to another URL two seconds later.
            if (g_bGoTo)
            {
                CreateTimer(2.0, GoToTimer, param1, TIMER_FLAG_NO_MAPCHANGE);
            }
        }
    }
    else if (action == MenuAction_End)
    {
        // Delete menu.
        delete menu;
    }
}

public void DoConnect(int iClient)
{
    // Check if client is in-game along with plugin is enabled.
    if (!IsClientInGame(iClient) || !g_bEnabled)
    {
        return;
    }

    // Check if client's cookies are cached.
    if (AreClientCookiesCached(iClient) && g_bPreventRejoin)
    {
        char tmp[11];

        // Sent cookie.
        GetClientCookie(iClient, g_cSent, tmp, sizeof(tmp));
        int sent = StringToInt(tmp);

        // Joined cookie.
        GetClientCookie(iClient, g_cJoined, tmp, sizeof(tmp));
        int joined = StringToInt(tmp);

        // Stop if we've sent them this before.
        if (sent || joined)
        {
            return;
        }
    }

    // Check menu option.
    if (g_bMenu)
    {
        // Create menu.
        Menu menu = new Menu(ConnectMenu);

        // Set title.
        menu.SetTitle("Join our Discord server and get rewards!");

        // Add yes and no items.
        menu.AddItem("0", "Yes!");
        menu.AddItem("1", "No.");

        // Display menu.
        menu.Display(iClient, 35);
    }
    else
    {
        // Show MOTD window.
        ShowURL(iClient, g_sLink);

        // Check if we should go to another URL two seconds later.
        if (g_bGoTo)
        {
            CreateTimer(2.0, GoToTimer, iClient, TIMER_FLAG_NO_MAPCHANGE);
        }

        // Check if we should notify client that we've invited them.
        if (g_bNotify)
        {
            PrintCenterText(iClient, "We have invited you to our Discord server! You will get rewards in the future if you join.");
        }
    }

    // Set cookie value for sent.
    char val[11] = "1";
    SetClientCookie(iClient, g_cSent, val);
}

public Action TmpTimer(Handle hTimer, any iClient)
{
    DoConnect(iClient);
}

public void OnClientPostAdminCheck(int iClient)
{
    if (g_iHook == 2)
    {
        CreateTimer(g_fWaitTime, TmpTimer, iClient, TIMER_FLAG_NO_MAPCHANGE);
    }
}

public Action Event_PlayerSpawn(Event event, const char[] sName, bool bDontBroadcast)
{
    // Get client ID.
    int iClient = event.GetInt("index");

    if (g_iHook == 1)
    {
        DoConnect(iClient);
    }

    return Plugin_Continue;
}