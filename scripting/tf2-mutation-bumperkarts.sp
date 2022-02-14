/*****************************/
//Pragma
#pragma semicolon 1
#pragma newdecls required

/*****************************/
//Defines
#define PLUGIN_NAME "[TF2] Mutation - Bumper Karts"
#define PLUGIN_DESCRIPTION "A random mutation which forces all players into Bumper Karts."
#define PLUGIN_VERSION "1.0.0"

/*****************************/
//Includes
#include <sourcemod>
#include <sdkhooks>
#include <tf2_stocks>
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

	AddCommandListener(DoSuicide, "explode");
	AddCommandListener(DoSuicide, "kill");
}

public void OnMapStart()
{
	PrecacheModel("models/player/items/taunts/bumpercar/parts/bumpercar.mdl");
	PrecacheModel("models/player/items/taunts/bumpercar/parts/bumpercar_nolights.mdl");
	
	PrecacheSound(")weapons/bumper_car_accelerate.wav");
	PrecacheSound(")weapons/bumper_car_decelerate.wav");
	PrecacheSound(")weapons/bumper_car_decelerate_quick.wav");
	PrecacheSound(")weapons/bumper_car_go_loop.wav");
	PrecacheSound(")weapons/bumper_car_hit_ball.wav");
	PrecacheSound(")weapons/bumper_car_hit_ghost.wav");
	PrecacheSound(")weapons/bumper_car_hit_hard.wav");
	PrecacheSound(")weapons/bumper_car_hit_into_air.wav");
	PrecacheSound(")weapons/bumper_car_jump.wav");
	PrecacheSound(")weapons/bumper_car_jump_land.wav");
	PrecacheSound(")weapons/bumper_car_screech.wav");
	PrecacheSound(")weapons/bumper_car_spawn.wav");
	PrecacheSound(")weapons/bumper_car_spawn_from_lava.wav");
	PrecacheSound(")weapons/bumper_car_speed_boost_start.wav");
	PrecacheSound(")weapons/bumper_car_speed_boost_stop.wav");
	
	char name[64];
	for(int i = 1; i <= 8; i++)
	{
		FormatEx(name, sizeof(name), "weapons/bumper_car_hit%d.wav", i);
		PrecacheSound(name);
	}
}

public void TF2_AddMutations()
{
	assigned_mutation = TF2_AddMutation("Bumper Karts", OnMutationStart, OnMutationEnd);
}

public void OnMutationStart(int mutation)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || !IsPlayerAlive(i))
			continue;
		
		TF2_RemoveAllWeapons(i);
		TF2_AddCondition(i, TFCond_HalloweenKart, TFCondDuration_Infinite);
	}
}

public void OnMutationEnd(int mutation)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || !IsPlayerAlive(i))
			continue;
		
		TF2_RemoveCondition(i, TFCond_HalloweenKart);
		TF2_RegeneratePlayer(i);
	}
}

public void Event_OnPlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));

	if (client > 0 && IsClientInGame(client) && IsPlayerAlive(client) && TF2_IsMutationActive(assigned_mutation))
	{
		TF2_RemoveAllWeapons(client);
		TF2_AddCondition(client, TFCond_HalloweenKart, TFCondDuration_Infinite);
	}
}

public Action DoSuicide(int client, const char[] command, int argc)
{
    if (TF2_IsMutationActive(assigned_mutation) && TF2_IsPlayerInCondition(client, TFCond_HalloweenKart))
	{
        SDKHooks_TakeDamage(client, 0, 0, 40000.0, (command[0] == 'e' ? DMG_BLAST : DMG_GENERIC) | DMG_PREVENT_PHYSICS_FORCE);
        return Plugin_Handled;
    }

    return Plugin_Continue;
}