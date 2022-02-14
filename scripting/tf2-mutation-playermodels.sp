/*****************************/
//Pragma
#pragma semicolon 1
#pragma newdecls required

/*****************************/
//Defines
#define PLUGIN_NAME "[TF2] Mutation - Player Models"
#define PLUGIN_DESCRIPTION "A random mutation which sets random models on players."
#define PLUGIN_VERSION "1.0.0"

/*****************************/
//Includes
#include <sourcemod>
#include <tf2_stocks>
#include <tf2items>
#include <tf2-mutations>

/*****************************/
//ConVars

/*****************************/
//Globals

int assigned_mutation = NO_MUTATION;

Handle g_hSdkEquipWearable;

bool g_bApply[MAXPLAYERS + 1];
char g_strClientModel[MAXPLAYERS + 1][PLATFORM_MAX_PATH];

char g_strModels[][] = 
{
	{ "models/bots/headless_hatman.mdl" }, 
	{ "models/bots/skeleton_sniper/skeleton_sniper.mdl" }, 
	{ "models/bots/skeleton_sniper_boss/skeleton_sniper_boss.mdl" }, 
	{ "models/bots/merasmus/merasmus.mdl" }, 
	{ "models/bots/demo/bot_demo.mdl" }, 
	{ "models/bots/demo/bot_sentry_buster.mdl" }, 
	{ "models/bots/engineer/bot_engineer.mdl" }, 
	{ "models/bots/heavy/bot_heavy.mdl" }, 
	{ "models/bots/medic/bot_medic.mdl" }, 
	{ "models/bots/pyro/bot_pyro.mdl" }, 
	{ "models/bots/scout/bot_scout.mdl" }, 
	{ "models/bots/sniper/bot_sniper.mdl" }, 
	{ "models/bots/soldier/bot_soldier.mdl" }, 
	{ "models/bots/spy/bot_spy.mdl" }, 
	{ "models/player/demo.mdl" }, 
	{ "models/player/engineer.mdl" }, 
	{ "models/player/heavy.mdl" }, 
	{ "models/player/medic.mdl" }, 
	{ "models/player/pyro.mdl" }, 
	{ "models/player/scout.mdl" }, 
	{ "models/player/sniper.mdl" }, 
	{ "models/player/soldier.mdl" }, 
	{ "models/player/spy.mdl" }, 
	{ "models/player/items/taunts/yeti/yeti.mdl" },
};

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

public void OnPluginStart()
{
	LoadTranslations("common.phrases");

	HookEvent("player_changeclass", Event_PlayerChangeClass, EventHookMode_Post);
	HookEvent("post_inventory_application", Event_InvApp, EventHookMode_Post);
	
	Handle gamedata = LoadGameConfigFile("sm-tf2.games");

	if (gamedata == null)
		SetFailState("Could not find sm-tf2.games gamedata!");
	
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetVirtual(GameConfGetOffset(gamedata, "RemoveWearable") - 1);
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	if ((g_hSdkEquipWearable = EndPrepSDKCall()) == null)
		LogMessage("Failed to create call: CBasePlayer::EquipWearable");
	
	delete gamedata;
}

public void OnMapStart()
{
	
}

public void TF2_AddMutations()
{
	assigned_mutation = TF2_AddMutation("Player Models", OnMutationStart, OnMutationEnd);
}

public void OnMutationStart(int mutation)
{
	for (int i = 1; i <= MaxClients; i++)
		if (IsClientInGame(i) && IsPlayerAlive(i))
			ApplyRandomModel(i);
}

public void OnMutationEnd(int mutation)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		g_strClientModel[i][0] = '\0';

		if (IsClientInGame(i) && IsPlayerAlive(i))
		{
			ApplyModel(i, "");
			SetEntProp(i, Prop_Send, "m_nRenderFX", 0);
		}
	}
}

public void Event_InvApp(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	if (TF2_IsMutationActive(assigned_mutation) && strlen(g_strClientModel[client]) > 0 && g_bApply[client])
	{
		Handle hItem = TF2Items_CreateItem(OVERRIDE_ALL | FORCE_GENERATION);
		TF2Items_SetClassname(hItem, "tf_wearable");
		TF2Items_SetItemIndex(hItem, 30601);
		TF2Items_SetQuality(hItem, 6);
		TF2Items_SetLevel(hItem, 1);
		
		int iItem = TF2Items_GiveNamedItem(client, hItem);
		
		delete hItem;
		
		SDKCall(g_hSdkEquipWearable, client, iItem);
		
		SetEntProp(client, Prop_Send, "m_nRenderFX", 6);
		SetEntProp(iItem, Prop_Data, "m_nModelIndexOverrides", PrecacheModel(g_strClientModel[client]));
		SetEntProp(iItem, Prop_Send, "m_bValidatedAttachedEntity", 1);
	}
}

public void Event_PlayerChangeClass(Event event, const char[] name, bool dontBroadcast)
{
	if (!TF2_IsMutationActive(assigned_mutation))
		return;
	
	int client = GetClientOfUserId(event.GetInt("userid"));
	ApplyRandomModel(client);
}

void ApplyRandomModel(int client)
{
	int iModel = GetRandomInt(0, sizeof(g_strModels) - 1);
	Format(g_strClientModel[client], PLATFORM_MAX_PATH, "%s", g_strModels[iModel]);
	
	char strModel[PLATFORM_MAX_PATH];
	Format(strModel, PLATFORM_MAX_PATH, "%s", g_strModels[iModel]);
	
	ApplyModel(client, strModel);
}

void ApplyModel(int client, const char[] model)
{
	SetVariantString(model);
	AcceptEntityInput(client, "SetCustomModel");
	
	SetEntProp(client, Prop_Send, "m_bUseClassAnimations", 1);
	
	g_bApply[client] = true;
} 