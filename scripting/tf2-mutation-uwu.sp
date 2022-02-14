/*****************************/
//Pragma
#pragma semicolon 1
#pragma newdecls required

/*****************************/
//Defines
#define PLUGIN_NAME "[TF2] Mutation - UwU"
#define PLUGIN_DESCRIPTION "A random mutation which makes everyone use UwU chat."
#define PLUGIN_VERSION "1.0.0"

/*****************************/
//Includes
#include <sourcemod>
#include <tf2_stocks>
#include <sdkhooks>
#include <tf2-mutations>
#include <chat-processor>

/*****************************/
//ConVars

/*****************************/
//Globals

int assigned_mutation = NO_MUTATION;

char faces[][] = {
    " owo",
    " UwU",
    " >w<",
    " ^w^",
    " OwO",
    " :3",
    " >:3",
    "~"
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
}

public void TF2_AddMutations()
{
	assigned_mutation = TF2_AddMutation("UwU", OnMutationStart, OnMutationEnd);
}

public void OnMutationStart(int mutation)
{

}

public void OnMutationEnd(int mutation)
{

}

public Action CP_OnChatMessage(int& author, ArrayList recipients, char[] flagstring, char[] name, char[] message, bool & processcolors, bool & removecolors)
{
	if (TF2_IsMutationActive(assigned_mutation))
	{
		ReplaceString(message, MAXLENGTH_MESSAGE, "l", "w", true);
		ReplaceString(message, MAXLENGTH_MESSAGE, "r", "w", true);
		ReplaceString(message, MAXLENGTH_MESSAGE, "L", "W", true);
		ReplaceString(message, MAXLENGTH_MESSAGE, "R", "W", true);

		if (GetRandomInt(1, 6) > 4)
			StrCat(message, MAXLENGTH_MESSAGE, faces[GetRandomInt(0, 7)]);

		return Plugin_Changed;
	}

	return Plugin_Continue;
}