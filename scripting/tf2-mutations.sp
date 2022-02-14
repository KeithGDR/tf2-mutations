/*****************************/
//Pragma
#pragma semicolon 1
#pragma newdecls required

/*****************************/
//Defines
#define PLUGIN_NAME "[TF2] Mutations"
#define PLUGIN_DESCRIPTION "Random gameplay elements each match for Team Fortress 2."
#define PLUGIN_VERSION "1.0.0"

#define MAX_MUTATIONS 256

/*****************************/
//Includes
#include <sourcemod>
#include <sdktools>
#include <misc-colors>
#include <tf2-mutations>

/*****************************/
//ConVars

ConVar convar_BasePercent;
ConVar convar_BasePercentPer;

/*****************************/
//Globals

int g_TotalMutations;

enum struct Mutations
{
	char name[64];
	int index;

	bool active;

	Handle plugin;

	PrivateForward start;
	PrivateForward end;

	ArrayList exclusions;

	void Init()
	{
		this.name[0] = '\0';
		this.index = NO_MUTATION;
		this.active = false;
		this.plugin = null;
		this.start = null;
		this.end = null;
		this.exclusions = null;
	}

	void Clear()
	{
		this.name[0] = '\0';
		this.index = NO_MUTATION;
		this.active = false;

		delete this.start;
		delete this.end;

		if (this.exclusions != null)
			this.exclusions.Clear();
	}

	void Add(const char[] name, Handle plugin, Function func_start, Function func_end)
	{
		strcopy(this.name, 64, name);
		this.index = g_TotalMutations;
		this.plugin = plugin;

		this.start = new PrivateForward(ET_Ignore, Param_Cell);
		this.start.AddFunction(plugin, func_start);

		this.end = new PrivateForward(ET_Ignore, Param_Cell);
		this.end.AddFunction(plugin, func_end);

		delete this.exclusions;
		this.exclusions = new ArrayList(ByteCountToCells(64));
	}

	void Fire(const char[] name)
	{
		if (this.plugin == null)
			return;
		
		if (StrEqual(name, "start", false) && this.start != null && this.start && GetForwardFunctionCount(this.start) > 0)
		{
			Call_StartForward(this.start);
			Call_PushCell(this.index);
			Call_Finish();
		}
		else if (StrEqual(name, "end", false) && this.end != null && this.end && GetForwardFunctionCount(this.end) > 0)
		{
			Call_StartForward(this.end);
			Call_PushCell(this.index);
			Call_Finish();
		}
	}

	void AddExclusion(const char[] exclusion)
	{
		if (this.exclusions.FindString(exclusion) != -1)
			return;
		
		this.exclusions.PushString(exclusion);
	}

	bool IsExcluded(const char[] exclusion)
	{
		return this.exclusions.FindString(exclusion) != -1;
	}
}

Mutations g_Mutations[MAX_MUTATIONS];

Handle g_Forward_AddMutations;

/*****************************/
//Plugin Info
public Plugin myinfo = 
{
	name = PLUGIN_NAME, 
	author = "Drixevel", 
	description = PLUGIN_DESCRIPTION, 
	version = PLUGIN_VERSION, 
	url = "https://drixevel.dev/"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	RegPluginLibrary("tf2-mutations");

	CreateNative("TF2_AddMutation", Native_AddMutation);
	CreateNative("TF2_IsMutationActive", Native_IsMutationActive);
	CreateNative("TF2_AddMutationExclusion", Native_AddMutationExclusion);

	g_Forward_AddMutations = CreateGlobalForward("TF2_AddMutations", ET_Ignore);

	return APLRes_Success;
}

public void OnPluginStart()
{
	LoadTranslations("common.phrases");

	convar_BasePercent = CreateConVar("sm_mutations_base_percent", "25", "Base percentage for mutations to be fired per round.", FCVAR_NOTIFY, true, 0.0, true, 100.0);
	convar_BasePercentPer = CreateConVar("sm_mutations_base_percent_per", "25", "Base percentage for mutations to be fired per round per mutation.", FCVAR_NOTIFY, true, 0.0, true, 100.0);
	
	//Make sure the data's consistent.
	for (int i = 0; i < MAX_MUTATIONS; i++)
		g_Mutations[i].Init();
	
	HookEvent("teamplay_round_start", Event_OnRoundStart);
	HookEvent("teamplay_round_win", Event_OnRoundEnd);

	RegAdminCmd("sm_mutations", Command_Mutations, ADMFLAG_GENERIC);
	RegAdminCmd("sm_syncmutations", Command_SyncMutations, ADMFLAG_GENERIC);
}

public void OnMapStart()
{
	PrecacheSound("ui/system_message_alert.wav");
}

public void OnAllPluginsLoaded()
{
	//Called here since all of the mutation plugins will be active.
	Call_StartForward(g_Forward_AddMutations);
	Call_Finish();
}

public int Native_AddMutation(Handle plugin, int numParams)
{
	int size;
	GetNativeStringLength(1, size); size++;

	char[] name = new char[size];
	GetNativeString(1, name, size);

	g_Mutations[g_TotalMutations].Add(name, plugin, GetNativeFunction(2), GetNativeFunction(3));

	int index = g_TotalMutations;
	g_TotalMutations++;
	
	return index;
}

public int Native_IsMutationActive(Handle plugin, int numParams)
{
	int mutation = GetNativeCell(1);

	if (mutation < 0 || mutation > MAX_MUTATIONS)
		return false;

	return g_Mutations[GetNativeCell(1)].active;
}

public int Native_AddMutationExclusion(Handle plugin, int numParams)
{
	int mutation = GetNativeCell(1);

	int size;
	GetNativeStringLength(2, size); size++;

	char[] sExclusion = new char[size];
	GetNativeString(2, sExclusion, size);

	g_Mutations[mutation].AddExclusion(sExclusion);
}

public void Event_OnRoundStart(Event event, const char[] name, bool dontBroadcast)
{
	if (GameRules_GetProp("m_bInWaitingForPlayers"))
		return;
	
	if (GetRandomFloat(0.0, 100.0) > convar_BasePercent.FloatValue)
	{
		CPrintToChatAll("{crimson}[{fullred}Mutations{crimson}] {beige}Disabled this round.");
		return;
	}
	
	char sMutations[64];
	for (int i = 0; i < g_TotalMutations; i++)
	{
		g_Mutations[i].active = view_as<bool>(GetRandomFloat(0.0, 100.0) <= convar_BasePercentPer.FloatValue);
		
		if (g_Mutations[i].active)
		{
			for (int x = 0; x < g_TotalMutations; x++)
				if (g_Mutations[i].IsExcluded(g_Mutations[x].name))
					g_Mutations[i].active = false;

			if (g_Mutations[i].active)
				Format(sMutations, sizeof(sMutations), "%s%s%s", sMutations, strlen(sMutations) == 0 ? " " : ", ", g_Mutations[i].name);
		}
	}

	CPrintToChatAll("{crimson}[{fullred}Mutations{crimson}] {beige}Active:{chartreuse}%s", strlen(sMutations) > 0 ? sMutations : " None Active");
	EmitSoundToAll("ui/system_message_alert.wav");
	
	CreateTimer(0.2, Timer_RoundStart, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_RoundStart(Handle timer)
{
	for (int i = 0; i < g_TotalMutations; i++)
		if (g_Mutations[i].active)
			g_Mutations[i].Fire("start");
}

public void Event_OnRoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	for (int i = 0; i < g_TotalMutations; i++)
	{
		if (!g_Mutations[i].active)
			continue;
		
		g_Mutations[i].Fire("end");
		g_Mutations[i].active = false;
	}
}

public Action Command_Mutations(int client, int args)
{
	OpenMutationsMenu(client);
	return Plugin_Handled;
}

void OpenMutationsMenu(int client)
{
	Menu menu = new Menu(MenuHandler_Mutations);
	menu.SetTitle("Available Mutations:");

	char sID[16]; char sDisplay[256];
	for (int i = 0; i < g_TotalMutations; i++)
	{
		IntToString(i, sID, sizeof(sID));
		Format(sDisplay, sizeof(sDisplay), "[%s] %s", g_Mutations[i].active ? "X" : "", g_Mutations[i].name);
		menu.AddItem(sID, sDisplay);
	}

	menu.Display(client, MENU_TIME_FOREVER);
}

public int MenuHandler_Mutations(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			char sID[16];
			menu.GetItem(param2, sID, sizeof(sID));
			int mutation = StringToInt(sID);

			g_Mutations[mutation].active = !g_Mutations[mutation].active;

			if (g_Mutations[mutation].active)
			{
				g_Mutations[mutation].Fire("start");
				CPrintToChatAll("{crimson}[{fullred}Mutations{crimson}] {beige}Enabled: {chartreuse}%s", g_Mutations[mutation].name);
			}
			else
			{
				g_Mutations[mutation].Fire("end");
				CPrintToChatAll("{crimson}[{fullred}Mutations{crimson}] {beige}Disabled: {chartreuse}%s", g_Mutations[mutation].name);
			}

			OpenMutationsMenu(param1);
		}
		case MenuAction_End:
			delete menu;
	}
}

public Action Command_SyncMutations(int client, int args)
{
	for (int i = 0; i < g_TotalMutations; i++)
	{
		g_Mutations[i].Fire("end");
		g_Mutations[i].active = false;
	}

	for (int i = 0; i < MAX_MUTATIONS; i++)
		g_Mutations[i].Clear();
	g_TotalMutations = 0;
	
	OnAllPluginsLoaded();
	CPrintToChat(client, "{crimson}[{fullred}Mutations{crimson}] {beige}Mutations have been synced.");
	return Plugin_Handled;
}