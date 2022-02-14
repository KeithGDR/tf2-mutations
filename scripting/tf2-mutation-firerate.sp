/*****************************/
//Pragma
#pragma semicolon 1
#pragma newdecls required

/*****************************/
//Defines
#define PLUGIN_NAME "[TF2] Mutation - Fire Rate"
#define PLUGIN_DESCRIPTION "A random mutation which adds fire rate to all players."
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
bool g_HasFireRate[4096 + 1];

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
	HookEvent("player_death", Event_OnPlayerDeath);
}

public void TF2_AddMutations()
{
	assigned_mutation = TF2_AddMutation("Fire Rate", OnMutationStart, OnMutationEnd);
}

public void OnMutationStart(int mutation)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || !IsPlayerAlive(i))
			continue;

		int weapon = -1;
		for (int x = 0; x < 5; x++)
		{
			if ((weapon = GetPlayerWeaponSlot(i, x)) == -1)
				continue;
			
			if (!g_HasFireRate[weapon])
			{
				g_HasFireRate[weapon] = true;
				TF2Attrib_SetFireRateBonus(weapon, 0.2);
			}
		}
	}
}

public void OnMutationEnd(int mutation)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || !IsPlayerAlive(i))
			continue;

		int weapon = -1;
		for (int x = 0; x < 5; x++)
		{
			if ((weapon = GetPlayerWeaponSlot(i, x)) == -1)
				continue;
			
			if (g_HasFireRate[weapon])
			{
				g_HasFireRate[weapon] = false;
				TF2Attrib_SetFireRateBonus(weapon, -0.2);
			}
		}
	}
}

public void Event_OnPlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));

	if (client > 0 && IsClientInGame(client) && IsPlayerAlive(client) && TF2_IsMutationActive(assigned_mutation))
	{
		int weapon = -1;
		for (int x = 0; x < 5; x++)
		{
			if ((weapon = GetPlayerWeaponSlot(client, x)) == -1)
				continue;
			
			if (!g_HasFireRate[weapon])
			{
				g_HasFireRate[weapon] = true;
				TF2Attrib_SetFireRateBonus(weapon, 0.2);
			}
		}
	}
}

public void Event_OnPlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));

	if (client > 0 && IsClientInGame(client) && IsPlayerAlive(client) && TF2_IsMutationActive(assigned_mutation))
	{
		int weapon = -1;
		for (int x = 0; x < 5; x++)
		{
			if ((weapon = GetPlayerWeaponSlot(client, x)) == -1)
				continue;
			
			if (g_HasFireRate[weapon])
			{
				g_HasFireRate[weapon] = false;
				TF2Attrib_SetFireRateBonus(weapon, -0.2);
			}
		}
	}
}

void TF2Attrib_SetFireRateBonus(int weapon, float bonus)
{
	float firerate;
	Address addr = TF2Attrib_GetByName(weapon, "fire rate bonus");

	firerate = addr != Address_Null ? TF2Attrib_GetValue(addr) - bonus : 1.00 - bonus;
	TF2Attrib_SetByName(weapon, "fire rate bonus", firerate);
}

public void OnEntityDestroyed(int entity)
{
	if (entity > 0)
		g_HasFireRate[entity] = false;
}