class StateAnalyzer extends StateAnalyzerBase;


// ==========================================================================
function string getState()
{
  if (kfGameType(level.game) != none)
  {
    if (level.NextURL != "")
    {
      return "CHANGING_MAP";
    }
    else if (kfGameType(level.game).bGameEnded == true)
    {
      if (isWipe())
        return "WIPE";
      else
        return "WIN";
    }
    else if (kfGameType(level.game).bWaitingToStartMatch == true)
      return "LOBBY";
    else if (kfGameType(level.game).bWaveInProgress == true)
      return "WAVE";
    else
      return "TRADER";
  }
  else
    return "UNDEFINED";
}


// function bool isWipe()
// {
//   local Controller c;
//   local byte aliveCount;
  
//   for (c = level.ControllerList; c != none; c = c.nextController)
//     if ((c.playerReplicationInfo != none) && c.bIsPlayer && !c.playerReplicationInfo.bOutOfLives && !c.playerReplicationInfo.bOnlySpectator )
//       aliveCount++;

//   if (aliveCount > 0)
//     return false;
//   return true;
// }


function bool isWipe()
{
  if (KFGameReplicationInfo(level.game.gameReplicationInfo).endGameType == 1)
    return true;
  return false;
}


// ==========================================================================
defaultproperties{}