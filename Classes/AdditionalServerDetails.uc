// Get additional server details and game states
// Author        : NikC-
// Home Repo     : https://github.com/InsultingPros/CustomServerDetails
// License       : https://www.gnu.org/licenses/gpl-3.0.en.html
class AdditionalServerDetails extends base_GR;


// pre defined gametype consts
const PTGameType="PerkTestMutV3.PTGameType";              // steamy test map v3
const KFPractiseGame1="KF-TheTestmap.KFPractiseGame";     // the test map v1
const KFPractiseGame2="KF-TheTestmap-2.KFPractiseGame";   // the test map v2

// pre defined state consts
const UD="UNDEFINED";
const UDOBJ="UNKNOWNOBJ";
const CHANGINGMAP="CHANGING_MAP";
const WIN="WIN";
const WIPE="WIPE";
const LOBBY="LOBBY";
const WAVE="WAVE";
const TRADER="TRADER";
const CUROBJ="CUROBJ";
const TESTINGMODE="TESTINGMODE";


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
    else if (kfstory != none)
    {
        kfstory_obj = kfstory_GRI.GetCurrentObjective();

        if (kfstory_obj != none)
            return CUROBJ;
        else
            return UDOBJ;
    }
    // KFGameType zone!!!
    else if (kfgt != none)
    {
        if (kfgt.bWaveInProgress == true)
            return WAVE;
        else
            return TRADER;
    }
    // not specified zone!!!
    else
        return UD;
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
    if (kfgt != none)
    {
        addSD(serverState, "Zeds left", max(kfgt.totalMaxMonsters + kfgt.numMonsters, 0));
        addSD(serverState, "Trader time", kfgt.waveCountDown);
        addSD(serverState, "CurrentWave", kfgt.waveNum + 1);
        addSD(serverState, "Waves total", kfgt.finalWave);
    }

    // KFStoryGameInfo!!!
    // for trader time ObjCondition_TraderTime -> Duration (60 by default)
    if (kfstory != none)
    {
        // N.B. if we use local string and assign it we will losse 0.15ms xD
        if (kfstory.CurrentObjective != none)
            addSD(serverState, "Current Objective", kfstory.CurrentObjective.HUD_Header.Header_Text);
        else
            addSD(serverState, "Current Objective", "not defined");
    }
}


// ==========================================================================
defaultproperties{}