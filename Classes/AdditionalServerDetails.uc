class AdditionalServerDetails extends GameRules;


// ==========================================================================
function getServerDetails(out GameInfo.serverResponseLine serverState)
{
  serverState.serverInfo.length = serverState.serverInfo.length + 1;
  serverState.serverInfo[serverState.serverInfo.length - 1].key = "Zeds left";
  serverState.serverInfo[serverState.serverInfo.length - 1].value = string(max(kfGameType(level.game).totalMaxMonsters + kfGameType(level.game).numMonsters,0));

  serverState.serverInfo.length = serverState.serverInfo.length + 1;
  serverState.serverInfo[serverState.serverInfo.length - 1].key = "Trader time";
  serverState.serverInfo[serverState.serverInfo.length - 1].value = string(kfGameType(level.game).waveCountDown);

  serverState.serverInfo.length = serverState.serverInfo.length + 1;
  serverState.serverInfo[serverState.serverInfo.length - 1].key = "CurrentWave";
  serverState.serverInfo[serverState.serverInfo.length - 1].value = string(kfGameType(level.game).waveNum + 1);

  serverState.serverInfo.length = serverState.serverInfo.length + 1;
  serverState.serverInfo[serverState.serverInfo.length - 1].key = "Waves total";
  serverState.serverInfo[serverState.serverInfo.length - 1].value = string(kfGameType(level.game).finalWave);
}


// ==========================================================================
defaultproperties{}