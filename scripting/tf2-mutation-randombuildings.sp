/*****************************/
//Pragma
#pragma semicolon 1
#pragma newdecls required

/*****************************/
//Defines
#define PLUGIN_NAME "[TF2] Mutation - Random Buildings"
#define PLUGIN_DESCRIPTION "A random mutation which spawns random buildings around the map."
#define PLUGIN_VERSION "1.0.0"

/*****************************/
//Includes
#include <sourcemod>
#include <tf2_stocks>
#include <spawnmaps>
#include <tf2-mutations>

/*****************************/
//ConVars

/*****************************/
//Globals

int assigned_mutation = NO_MUTATION;

ArrayList g_Buildings;

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
	g_Buildings = new ArrayList();
}

public void OnPluginEnd()
{
	if (!TF2_IsMutationActive(assigned_mutation))
		return;
	
	int building;
	for (int i = 0; i < g_Buildings.Length; i++)
		if ((building = EntRefToEntIndex(g_Buildings.Get(i))) != -1)
			AcceptEntityInput(building, "Kill");
}

public void TF2_AddMutations()
{
	assigned_mutation = TF2_AddMutation("Random Buildings", OnMutationStart, OnMutationEnd);
	TF2_AddMutationExclusion(assigned_mutation, "Spells");
}

public void OnMutationStart(int mutation)
{
	int total = SpawnMaps_GetTotalSpawns();

	if (total < 1)
		return;
	
	total = GetRandomInt(0, total - 1) / 2;

	float origin[3]; float angles[3]; int building;
	for (int i = 0; i < total; i++)
	{
		SpawnMaps_GetRandom(origin);
		//angles[1] = GetRandomFloat(0.0, 360.0);

		if (GetRandomFloat(0.0, 100.0) >= 50.0)
			building = TF2_SpawnSentry(-1, origin, angles, (GetRandomFloat(0.0, 100.0) >= 50.0) ? TFTeam_Red : TFTeam_Blue);
		else
			building = TF2_SpawnDispenser(-1, origin, angles, (GetRandomFloat(0.0, 100.0) >= 50.0) ? TFTeam_Red : TFTeam_Blue);
		
		g_Buildings.Push(EntIndexToEntRef(building));
	}
}

public void OnMutationEnd(int mutation)
{
	if (g_Buildings.Length < 1)
		return;
	
	int building;
	for (int i = 0; i < g_Buildings.Length; i++)
		if ((building = EntRefToEntIndex(g_Buildings.Get(i))) != -1)
			AcceptEntityInput(building, "Kill");
	
	g_Buildings.Clear();
}

int TF2_SpawnSentry(int builder, float Position[3], float Angle[3], TFTeam team = TFTeam_Unassigned, int level = 0, bool mini = false, bool disposable = false)
{
	static const float m_vecMinsMini[3] = {-15.0, -15.0, 0.0}, m_vecMaxsMini[3] = {15.0, 15.0, 49.5};
	static const float m_vecMinsDisp[3] = {-13.0, -13.0, 0.0}, m_vecMaxsDisp[3] = {13.0, 13.0, 42.9};
	
	int sentry = CreateEntityByName("obj_sentrygun");
	
	if (IsValidEntity(sentry))
	{
		char sLevel[12];
		IntToString(level, sLevel, sizeof(sLevel));
		
		if (builder > 0)
			AcceptEntityInput(sentry, "SetBuilder", builder);

		SetVariantInt(view_as<int>(team));
		AcceptEntityInput(sentry, "SetTeam");
		
		DispatchKeyValueVector(sentry, "origin", Position);
		DispatchKeyValueVector(sentry, "angles", Angle);
		DispatchKeyValue(sentry, "defaultupgrade", sLevel);
		DispatchKeyValue(sentry, "spawnflags", "4");
		SetEntProp(sentry, Prop_Send, "m_bBuilding", 1);
		
		if (mini || disposable)
		{
			SetEntProp(sentry, Prop_Send, "m_bMiniBuilding", 1);
			SetEntProp(sentry, Prop_Send, "m_nSkin", level == 0 ? view_as<int>(team) : view_as<int>(team) - 2);
		}
		
		if (mini)
		{
			DispatchSpawn(sentry);
			
			SetVariantInt(100);
			AcceptEntityInput(sentry, "SetHealth");
			
			SetEntPropFloat(sentry, Prop_Send, "m_flModelScale", 0.75);
			SetEntPropVector(sentry, Prop_Send, "m_vecMins", m_vecMinsMini);
			SetEntPropVector(sentry, Prop_Send, "m_vecMaxs", m_vecMaxsMini);
		}
		else if (disposable)
		{
			SetEntProp(sentry, Prop_Send, "m_bDisposableBuilding", 1);
			DispatchSpawn(sentry);
			
			SetVariantInt(100);
			AcceptEntityInput(sentry, "SetHealth");
			
			SetEntPropFloat(sentry, Prop_Send, "m_flModelScale", 0.60);
			SetEntPropVector(sentry, Prop_Send, "m_vecMins", m_vecMinsDisp);
			SetEntPropVector(sentry, Prop_Send, "m_vecMaxs", m_vecMaxsDisp);
		}
		else
		{
			SetEntProp(sentry, Prop_Send, "m_nSkin", view_as<int>(team) - 2);
			DispatchSpawn(sentry);
		}
	}
	
	return sentry;
}

int TF2_SpawnDispenser(int builder, float Position[3], float Angle[3], TFTeam team = TFTeam_Unassigned, int level = 0)
{
	int dispenser = CreateEntityByName("obj_dispenser");
	
	if (IsValidEntity(dispenser))
	{
		char sLevel[12];
		IntToString(level, sLevel, sizeof(sLevel));
		
		DispatchKeyValueVector(dispenser, "origin", Position);
		DispatchKeyValueVector(dispenser, "angles", Angle);
		DispatchKeyValue(dispenser, "defaultupgrade", sLevel);
		DispatchKeyValue(dispenser, "spawnflags", "4");
		SetEntProp(dispenser, Prop_Send, "m_bBuilding", 1);
		DispatchSpawn(dispenser);

		SetVariantInt(view_as<int>(team));
		AcceptEntityInput(dispenser, "SetTeam");
		SetEntProp(dispenser, Prop_Send, "m_nSkin", view_as<int>(team) - 2);
		
		ActivateEntity(dispenser);
		
		AcceptEntityInput(dispenser, "SetBuilder", builder);
	}
	
	return dispenser;
}