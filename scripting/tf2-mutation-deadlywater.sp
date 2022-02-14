/*****************************/
//Pragma
#pragma semicolon 1
#pragma newdecls required

/*****************************/
//Defines
#define PLUGIN_NAME "[TF2] Mutation - Deadly Water"
#define PLUGIN_DESCRIPTION "A random mutation which kills players instantly if they touch water."
#define PLUGIN_VERSION "1.0.0"

/*****************************/
//Includes
#include <sourcemod>
#include <tf2_stocks>
#include <sdkhooks>
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
}

public void TF2_AddMutations()
{
	assigned_mutation = TF2_AddMutation("Deadly Water", OnMutationStart, OnMutationEnd);
	if (assigned_mutation) {}
}

public void OnMutationStart(int mutation)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i))
			continue;
		
		SDKHook(i, SDKHook_PostThink, OnPostThink);
	}
}

public void OnPostThink(int client)
{
	if (!IsClientInGame(client) || !IsPlayerAlive(client))
		return;
	
	if (GetEntProp(client, Prop_Data, "m_nWaterLevel") > 1)
		SDKHooks_TakeDamage(client, 0, client, 99999.0, DMG_DROWN);
}

public void OnMutationEnd(int mutation)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i))
			continue;
		
		SDKUnhook(i, SDKHook_PostThink, OnPostThink);
	}
}