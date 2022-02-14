#if defined __tf2_mutations_included
	#endinput
#endif
#define __tf2_mutations_included

#define NO_MUTATION -1

typedef OnMutationStartFunc = function void (int mutation);
typedef OnMutationEndFunc = function void (int mutation);

native int TF2_AddMutation(const char[] name, OnMutationStartFunc func_start, OnMutationEndFunc func_end);
native bool TF2_IsMutationActive(int mutation);
native void TF2_AddMutationExclusion(int mutation, const char[] exclusion);
forward void TF2_AddMutations();

#if !defined REQUIRE_PLUGIN
public void __pl_tf2_mutations_SetNTVOptional()
{
	MarkNativeAsOptional("TF2_AddMutation");
	MarkNativeAsOptional("TF2_IsMutationActive");
	MarkNativeAsOptional("TF2_AddMutationExclusion");
}
#endif

public SharedPlugin __pl_tf2_mutations =
{
	name = "tf2-mutations",
	file = "tf2-mutations.smx",
#if defined REQUIRE_PLUGIN
	required = 1
#else
	required = 0
#endif
};