/*****************************/
//Pragma
#pragma semicolon 1
#pragma newdecls required

/*****************************/
//Defines
#define PLUGIN_NAME "[TF2] Mutation - More Health"
#define PLUGIN_DESCRIPTION "A random mutation which gives all players more health."
#define PLUGIN_VERSION "1.0.0"

/*****************************/
//Includes
#include <sourcemod>
#include <tf2_stocks>
#include <sdkhooks>
#include <tf2attributes>
#include <tf2-mutations>

/*****************************/
//ConVars

/*****************************/
//Globals

int assigned_mutation = NO_MUTATION;

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

	HookEvent("player_spawn", Event_OnPlayerSpawn);
	HookEvent("player_changeclass", Event_OnPlayerSpawn);

	RegAdminCmd("sm_getmaxhealth", Command_GetMaxHealth, ADMFLAG_ROOT);
}

public Action Command_GetMaxHealth(int client, int args)
{
	PrintToChat(client, "MaxHealth: %i", GetEntProp(client, Prop_Data, "m_iMaxHealth"));
	return Plugin_Handled;
}

public void TF2_AddMutations()
{
	assigned_mutation = TF2_AddMutation("More Health", OnMutationStart, OnMutationEnd);
}

public void OnMutationStart(int mutation)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || !IsPlayerAlive(i))
			continue;
		
		SetEntityHealth(i, GetEntProp(i, Prop_Data, "m_iMaxHealth") + 100);
		TF2Attrib_SetByName(i, "max health additive bonus", 100.0);
	}
}

public void OnMutationEnd(int mutation)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || !IsPlayerAlive(i))
			continue;
		
		SetEntityHealth(i, GetEntProp(i, Prop_Data, "m_iMaxHealth"));
		TF2Attrib_RemoveByName(i, "max health additive bonus");
	}
}

public void Event_OnPlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));

	if (client > 0 && IsClientInGame(client) && IsPlayerAlive(client) && TF2_IsMutationActive(assigned_mutation))
		SetEntityHealth(client, GetEntProp(client, Prop_Data, "m_iMaxHealth") + 100);
}