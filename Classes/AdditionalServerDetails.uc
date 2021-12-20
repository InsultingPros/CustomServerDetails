class AdditionalServerDetails extends base_GR;


// pre defined gametype consts
var protected const string PTGameType;        // steamy test map v3
var protected const string KFPractiseGame1;   // the test map v1
var protected const string KFPractiseGame2;   // the test map v2

// pre defined state consts
var protected const string UNDEFINED;
var protected const string CHANGINGMAP;
var protected const string WIN;
var protected const string WIPE;
var protected const string LOBBY;
var protected const string WAVE;
var protected const string TRADER;
var protected const string CUROBJ;
var protected const string TESTINGMODE;


// ==========================================================================
// 0.002-0.004 ms, yusss
function string getState()
{
  local KF_StoryObjective kfstory_obj;

  // BASIC STATES for all gametypes
  if (level.NextURL != "")
  {
    return CHANGINGMAP;
  }
  else if (level.game.bGameEnded)
  {
    if (isWipe())
      return WIPE;
    else
      return WIN;
  }
  else if (level.game.bWaitingToStartMatch)
  {
    return LOBBY;
  }

  // TEST MAPS zone!!!
  if (GameTypeName == PTGameType || GameTypeName == KFPractiseGame1 || GameTypeName == KFPractiseGame2)
  {
    return TESTINGMODE;
  }
  // KFStoryGameInfo zone!!!
  else if (GameTypeName == KFStoryGame)
  {
    kfstory_obj = kfstory_GRI.GetCurrentObjective();

    if (kfstory_obj != none)
      return CUROBJ;
    else
      return UNDEFINED;
  }
  // KFGameType zone!!!
  else if (GameTypeName == KFGameType)
  {
    if (kfgt.bWaveInProgress == true)
      return WAVE;
    else
      return TRADER;
  }
  // not specified zone!!!
  else
    return UNDEFINED;
}


final function bool isWipe()
{
  if (KFGameReplicationInfo(level.game.gameReplicationInfo).endGameType == 1)
    return true;
  return false;
}


// ==========================================================================
// 0.3-0.6 ms
function getServerDetails(out GameInfo.serverResponseLine serverState)
{
  // KFGameType!!!
  // have to check this, coz you won't believe there are gametypes that do not extend KFGameType
  if (GameTypeName == KFGameType)
  {
    addSD(serverState, "Zeds left", max(kfgt.totalMaxMonsters + kfgt.numMonsters, 0));
    addSD(serverState, "Trader time", kfgt.waveCountDown);
    addSD(serverState, "CurrentWave", kfgt.waveNum + 1);
    addSD(serverState, "Waves total", kfgt.finalWave);
  }

  // KFStoryGameInfo!!!
  // for trader time ObjCondition_TraderTime -> Duration (60 by default)
  if (GameTypeName == KFStoryGame)
  {
    // N.B. if we use local string and assign it we will losse 0.15ms xD
    if (kfstory.CurrentObjective != none)
      addSD(serverState, "Current Objective", kfstory.CurrentObjective.HUD_Header.Header_Text);
    else
      addSD(serverState, "Current Objective", "not defined");
  }
}


// ==========================================================================
defaultproperties
{
  // test map gametypes
  PTGameType="PerkTestMutV3.PTGameType"
  KFPractiseGame1="KF-TheTestmap.KFPractiseGame"
  KFPractiseGame2="KF-TheTestmap-2.KFPractiseGame"

  // consts
  UNDEFINED="UNDEFINED"
  CHANGINGMAP="CHANGING_MAP"
  WIN="WIN"
  WIPE="WIPE"
  LOBBY="LOBBY"
  WAVE="WAVE"
  TRADER="TRADER"
  CUROBJ="CUROBJ"
  TESTINGMODE="TESTINGMODE"
}