/*****************************/
//Pragma
#pragma semicolon 1
#pragma newdecls required

/*****************************/
//Defines
#define PLUGIN_NAME "[TF2] Mutation - Spells"
#define PLUGIN_DESCRIPTION "A random mutation which automatically grants spells to players."
#define PLUGIN_VERSION "1.0.0"

/*****************************/
//Includes
#include <sourcemod>
#include <tf2_stocks>
#include <sdkhooks>
#include <spawnmaps>
#include <tf2-mutations>

/*****************************/
//ConVars

/*****************************/
//Globals

int assigned_mutation = NO_MUTATION;

int g_iHolidayEntity = -1;
Handle g_SpawnTimer;

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

public void OnPluginEnd()
{
	if (!TF2_IsMutationActive(assigned_mutation))
		return;
	
	int entity = -1;
	while ((entity = FindEntityByClassname(entity, "tf_spell_pickup")) != -1)
		AcceptEntityInput(entity, "Kill");
}

public void OnMapEnd()
{
	g_SpawnTimer = null;
}

public void TF2_AddMutations()
{
	assigned_mutation = TF2_AddMutation("Spells", OnMutationStart, OnMutationEnd);
	TF2_AddMutationExclusion(assigned_mutation, "Random Buildings");
}

public void OnMutationStart(int mutation)
{
	int holiday = GetOrCreateHolidayEntity();
	SetVariantInt(1);
	AcceptEntityInput(holiday, "HalloweenSetUsingSpells");

	StopTimer(g_SpawnTimer);
	g_SpawnTimer = CreateTimer(GetRandomFloat(30.0, 60.0), Timer_SpawnSpells, _, TIMER_FLAG_NO_MAPCHANGE);
	TriggerTimer(g_SpawnTimer, true);
}

public Action Timer_SpawnSpells(Handle timer)
{
	if (!TF2_IsMutationActive(assigned_mutation))
	{
		g_SpawnTimer = null;
		return Plugin_Stop;
	}

	int total = SpawnMaps_GetTotalSpawns();

	if (total < 1)
	{
		g_SpawnTimer = CreateTimer(GetRandomFloat(30.0, 60.0), Timer_SpawnSpells, _, TIMER_FLAG_NO_MAPCHANGE);
		return Plugin_Stop;
	}

	total = GetRandomInt(0, total - 1);

	float origin[3]; int spell; float angles[3];
	for (int i = 0; i < total; i++)
	{
		SpawnMaps_GetRandom(origin);

		spell = CreateEntityByName("tf_spell_pickup");

		if (IsValidEntity(spell))
		{
			angles[1] = GetRandomFloat(0.0, 360.0);
			DispatchSpawn(spell);
			TeleportEntity(spell, origin, angles, NULL_VECTOR);
		}
	}

	g_SpawnTimer = CreateTimer(GetRandomFloat(30.0, 60.0), Timer_SpawnSpells, _, TIMER_FLAG_NO_MAPCHANGE);
	return Plugin_Stop;
}

public void OnMutationEnd(int mutation)
{
	int holiday = GetOrCreateHolidayEntity();
	SetVariantInt(0);
	AcceptEntityInput(holiday, "HalloweenSetUsingSpells");

	StopTimer(g_SpawnTimer);

	int entity = -1;
	while ((entity = FindEntityByClassname(entity, "tf_spell_pickup")) != -1)
		AcceptEntityInput(entity, "Kill");
}

int GetOrCreateHolidayEntity()
{
	if (g_iHolidayEntity == -1)
	{
		g_iHolidayEntity = FindEntityByClassname(-1, "tf_logic_holiday");
		
		if (g_iHolidayEntity == -1)
		{
			g_iHolidayEntity = CreateEntityByName("tf_logic_holiday");
			
			if (g_iHolidayEntity != -1)
				DispatchSpawn(g_iHolidayEntity);
		}
	}

	if (g_iHolidayEntity == -1)
		ThrowError("Failed to find or create tf_logic_holiday entity.");

	return g_iHolidayEntity;
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if (StrEqual(classname, "tf_logic_holiday"))
		g_iHolidayEntity = entity;
}

public void OnEntityDestroyed(int entity)
{
	if (g_iHolidayEntity == entity)
		g_iHolidayEntity = -1;
}

bool StopTimer(Handle& timer)
{
	if (timer != null)
	{
		KillTimer(timer);
		timer = null;
		return true;
	}
	
	return false;
}