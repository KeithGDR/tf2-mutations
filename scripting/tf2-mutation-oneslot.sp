/*****************************/
//Pragma
#pragma semicolon 1
#pragma newdecls required

/*****************************/
//Defines
#define PLUGIN_NAME "[TF2] Mutation - One Slot"
#define PLUGIN_DESCRIPTION "A random mutation which sets all players or certain teams to 1 slot."
#define PLUGIN_VERSION "1.0.0"

/*****************************/
//Includes
#include <sourcemod>
#include <tf2_stocks>
#include <sdkhooks>
#include <tf2-mutations>

#include <misc-colors>

/*****************************/
//ConVars

/*****************************/
//Globals

int assigned_mutation = NO_MUTATION;
int random_slot = -1;

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
}

public void TF2_AddMutations()
{
	assigned_mutation = TF2_AddMutation("One Slot", OnMutationStart, OnMutationEnd);
	TF2_AddMutationExclusion(assigned_mutation, "One Class");
}

public void OnMutationStart(int mutation)
{
	random_slot = GetRandomInt(0, 2);

	char sSlot[32];
	switch (random_slot)
	{
		case 0:
			strcopy(sSlot, sizeof(sSlot), "Primary Only");
		case 1:
			strcopy(sSlot, sizeof(sSlot), "Secondary Only");
		case 2:
			strcopy(sSlot, sizeof(sSlot), "Melee Only");
	}

	CPrintToChatAll("{crimson}[{fullred}Mutations{crimson}] {beige}Slot Chosen: {chartreuse}%s", sSlot);

	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || !IsPlayerAlive(i))
			continue;
		
		EquipWeaponSlot(i, random_slot);
		SDKHook(i, SDKHook_WeaponSwitch, OnWeaponSwitch);
		SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);
	}
}

public Action OnWeaponSwitch(int client, int weapon)
{
	bool isengi = TF2_GetPlayerClass(client) == TFClass_Engineer;
	if (isengi && GetActiveWeaponSlot(client) > 2)
		return Plugin_Continue;
	
	int max = isengi ? 1 : 2;
	
	if (IsValidEntity(weapon) && TF2_IsMutationActive(assigned_mutation) && random_slot != -1 && GetWeaponSlot(client, weapon) != random_slot && GetWeaponSlot(client, weapon) <= max)
		return Plugin_Stop;
	
	return Plugin_Continue;
}

public Action OnTakeDamage(int victim, int& attacker, int& inflictor, float& damage, int& damagetype, int& weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	if (attacker < 1 || attacker > MaxClients)
		return Plugin_Continue;
	
	if (TF2_GetPlayerClass(attacker) == TFClass_Engineer && GetWeaponSlot(attacker, weapon) == 2 && random_slot != -1 && GetWeaponSlot(attacker, weapon) != random_slot)
	{
		damage = 0.0;
		return Plugin_Changed;
	}

	return Plugin_Continue;
}

stock int GetActiveWeaponSlot(int client)
{
	if (client == 0 || client > MaxClients || !IsClientInGame(client) || !IsPlayerAlive(client))
		return -1;
	
	int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	
	if (weapon == 0 || weapon < MaxClients || !IsValidEntity(weapon))
		return -1;
	
	for (int i = 0; i < 5; i++)
	{
		if (GetPlayerWeaponSlot(client, i) != weapon)
			continue;

		return i;
	}

	return -1;
}

public void OnMutationEnd(int mutation)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || !IsPlayerAlive(i))
			continue;
		
		EquipWeaponSlot(i, 0);
		SDKUnhook(i, SDKHook_WeaponSwitch, OnWeaponSwitch);
		SDKUnhook(i, SDKHook_OnTakeDamage, OnTakeDamage);
	}

	random_slot = -1;
}

public void Event_OnPlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));

	if (client > 0 && IsClientInGame(client) && IsPlayerAlive(client) && TF2_IsMutationActive(assigned_mutation))
	{
		EquipWeaponSlot(client, random_slot);
	}
}

stock void EquipWeaponSlot(int client, int slot)
{
	int iWeapon = GetPlayerWeaponSlot(client, slot);
	
	if (IsValidEntity(iWeapon))
	{
		char class[64];
		GetEntityClassname(iWeapon, class, sizeof(class));
		FakeClientCommand(client, "use %s", class);
	}
}

stock int GetWeaponSlot(int client, int weapon)
{
	if (client == 0 || client > MaxClients || !IsClientInGame(client) || !IsPlayerAlive(client) || weapon == 0 || weapon < MaxClients || !IsValidEntity(weapon))
		return -1;

	for (int i = 0; i < 5; i++)
	{
		if (GetPlayerWeaponSlot(client, i) != weapon)
			continue;

		return i;
	}

	return -1;
}