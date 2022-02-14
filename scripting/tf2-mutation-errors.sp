/*****************************/
//Pragma
#pragma semicolon 1
#pragma newdecls required

/*****************************/
//Defines
#define PLUGIN_NAME "[TF2] Mutation - Errors"
#define PLUGIN_DESCRIPTION "A random mutation which sets random models to errors."
#define PLUGIN_VERSION "1.0.0"

/*****************************/
//Includes
#include <sourcemod>
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
}

public void OnMapStart()
{
	PrecacheModel("error.mdl");
}

public void TF2_AddMutations()
{
	assigned_mutation = TF2_AddMutation("Errors", OnMutationStart, OnMutationEnd);
	if (assigned_mutation) {}
}

public void OnMutationStart(int mutation)
{
	int entity = -1;
	while ((entity = FindEntityByClassname(entity, "prop_*")) != -1)
		if (GetRandomFloat(0.0, 100.0) >= 50.0)
			SetEntityModel(entity, "error.mdl");
}

public void OnMutationEnd(int mutation)
{

}