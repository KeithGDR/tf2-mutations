/*****************************/
//Pragma
#pragma semicolon 1
#pragma newdecls required

/*****************************/
//Defines
#define PLUGIN_NAME "[TF2] Mutation - Damage"
#define PLUGIN_DESCRIPTION "A random mutation which adds damage to all players."
#define PLUGIN_VERSION "1.0.0"

/*****************************/
//Includes
#include <sourcemod>
#include <tf2_stocks>
#include <tf2-mutations>

#include <tf2attributes>

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
}

public void TF2_AddMutations()
{
	assigned_mutation = TF2_AddMutation("Damage", OnMutationStart, OnMutationEnd);
}

public void OnMutationStart(int mutation)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || !IsPlayerAlive(i))
			continue;

		TF2Attrib_SetByName(i, "damage bonus", 1.0 + 0.25);
	}
}

public void OnMutationEnd(int mutation)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || !IsPlayerAlive(i))
			continue;

		TF2Attrib_RemoveByName(i, "damage bonus");
	}
}

public void Event_OnPlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));

	if (client > 0 && IsClientInGame(client) && IsPlayerAlive(client) && TF2_IsMutationActive(assigned_mutation))
	{
		TF2Attrib_SetByName(client, "move speed bonus", 1.0 + 0.25);
		TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.0);
	}
}