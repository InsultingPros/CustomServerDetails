class CSDMasterServerUplink extends MasterServerUplink
  config(CustomServerDetails);


// ==========================================================================
// variables

// To understand what's going on here, just look at sample .ini file. It's very simple.
struct displayedDetails
{
  var  string  name;        // name of the key
  var  string  keyTag;      // color tag of key (name)
  var  string  valTag;      // color tag of value
  var  bool    bChangeName; // change name of the key
  var  string  newName;     // new name
  var  bool    bCustom;     // if true, set name and customValue (and ofc their colors)
  var  string  customValue; 
};

struct infoBlockPattern
{
  var  string  state;
  var  string  pattern;
};

struct infoBlockKey
{
  var  string  detail;
  var  string  key;
};

var  config  bool                         bChangeServerDetails; //if true, you can filter/change/add server details
var  config  array<displayedDetails>      displayedServerDetails; //server details you want to show
var  config  array<string>                extendedServerDetailsClassName; //class which add extra server details (must be extended from 'GameRules')
var  config  int                          refreshTime; //[seconds] how frequently refresh and send informaton to master server
var  config  bool                         bCustomServerName; //allows you to use custom server name
var  config  string                       serverName; //obviously
var  config  bool                         bMapColor; //obviously
var  config  string                       mapColor; //obviously
var  config  bool                         bInfoBlockInServerName; //if true, adds block with information in the server's name, there must be %infoBlock% in the "serverName"
var  config  string                       stateAnalyzerClassName; //special class, which return the state of the game (must be extended from 'StateAnalyzerBase')
var  config  array<infoBlockPattern>      infoBlockPatterns; //there is unique name of the server for every state of the game 
var  config  array<infoBlockKey>          infoBlockKeys; //custom %keys%, which are used in the "infoBlock", so some server details can be showed in the server's name
var  config  bool                         bAnotherNicknamesStyle; //if true, you can define the style of nicknames, depends on state of the player (dead, spectating etc.)
var  config  string                       playerDeadNicknamePattern; //style of player's nickname when he is dead. must consists %nickname%
var  config  string                       playerSpectatingNicknamePattern;//same, but for spectating state
var  config  string                       playerAwaitingNicknamePattern; //same
var  config  string                       playerAliveNicknamePattern; //same
var  config  bool                         bColorNicknames; //change color keys (like ^2 or ^6) to real colors

var                GameInfo.serverResponseLine  srl;
var                KFGameType                   kfgt;
var                StateAnalyzerBase            stateAnalyzer;


// for reference
// GameInfo:
// struct native export ServerResponseLine
// {
//     var() int ServerID;
//     var() string IP;
//     var() int Port;
//     var() int QueryPort;
//     var() string serverName;
//     var() string MapName;
//     var() string GameType;
//     var() int CurrentPlayers;
//     var() int MaxPlayers;
//     var() int CurrentWave;
//     var() int FinalWave;
//     var() int Ping;
//     var() int Flags;
//     var() string SkillLevel;
//     var() array<KeyValuePair> serverInfo;
//     var() array<PlayerResponseLine> PlayerInfo;
// };


// ==========================================================================
event postBeginPlay()
{
  local  int                       i;
  local  class<GameRules>          extendedServerDetailsClass;
  local  class<StateAnalyzerBase>  stateAnalyzerClass;

  setTimer(refreshTime, true);

  // dynamic load stateAnalyzer
  stateAnalyzerClass = class<StateAnalyzerBase>(dynamicLoadObject(stateAnalyzerClassName, class'Class'));
  if (bInfoBlockInServerName && bCustomServerName)
  {
    if (stateAnalyzerClass != none)
      stateAnalyzer = spawn(stateAnalyzerClass);
    else
      log("CustomServerDetails[WARNING]: Class"@stateAnalyzerClassName@"(stateAnalyzerClassName) wasn't found. Dynamic changing of server name won't work.");		
    if (inStr(serverName, "%infoBlock%") == -1)
      log("CustomServerDetails[WARNING]: You set 'bInfoBlockInServerName=true', but %infoBlock% wasn't found in 'serverName'. InfoBlock will be placed at the end os server's name.");		
  }

  // add to the game special custom GameRules
  // so these GameRules will add extra details on the server description
  for (i = 0; i < extendedServerDetailsClassName.length; i++)
  {
    extendedServerDetailsClass = class<GameRules>(dynamicLoadObject(extendedServerDetailsClassName[i], class'Class'));

    if (extendedServerDetailsClass == none)
    {
      log("CustomServerDetails[WARNING]: Class '"$extendedServerDetailsClassName[i]$"' (extendedServerDetailsClassName) wasn't found.");
      continue;
    }
    if (level.game.gameRulesModifiers == none)
      level.game.gameRulesModifiers = spawn(extendedServerDetailsClass);
    else
      level.game.gameRulesModifiers.AddGameRules(spawn(extendedServerDetailsClass));
  }

  if (bAnotherNicknamesStyle)
  {
    if (inStr(playerDeadNicknamePattern, "%nickname%") == -1)
      log("CustomServerDetails[WARNING]: You set 'bAnotherNicknamesStyle=true'. But you didn't paste %nickname% in 'playerDeadNicknamePattern'. JUST DO IT!");		
    if (inStr(playerSpectatingNicknamePattern, "%nickname%") == -1)
      log("CustomServerDetails[WARNING]: You set 'bAnotherNicknamesStyle=true'. But you didn't paste %nickname% in 'playerSpectatingNicknamePattern'. JUST DO IT!");		
    if (inStr(playerAwaitingNicknamePattern, "%nickname%") == -1)
      log("CustomServerDetails[WARNING]: You set 'bAnotherNicknamesStyle=true'. But you didn't paste %nickname% in 'playerAwaitingNicknamePattern'. JUST DO IT!");		
    if (inStr(playerAliveNicknamePattern, "%nickname%") == -1)
      log("CustomServerDetails[WARNING]: You set 'bAnotherNicknamesStyle=true'. But you didn't paste %nickname% in 'playerAliveNicknamePattern'. JUST DO IT!");		
  }
}


function timer()
{
  refresh();
}


event refresh()
{
  // ask server for all iformation it can give
  level.game.getServerInfo(srl);
  getServerPlayers();
  level.game.getServerDetails(srl);

  // change server name to custom one
  if (bCustomServerName)
    dynamicChangeServerName();

  // filter/add/change server details 
  if (bChangeServerDetails)
    filterServerDetails();

  if (bMapColor)
    srl.mapName = class'o_Utility'.static.ParseTags(mapColor$srl.mapName);

  serverState = srl;
}


function filterServerDetails()
{
  local int i, j;

  // delete all details that are not in allowed list
  // change detail names if necessary, add color
  for (i = srl.serverInfo.length - 1; i >= 0; i--)
  {
    for (j = 0; j < displayedServerDetails.length; j++)
    {
      if (srl.serverInfo[i].key ~= displayedServerDetails[j].name && !displayedServerDetails[j].bCustom)
      {
        if (displayedServerDetails[j].bChangeName)
          srl.serverInfo[i].key = displayedServerDetails[j].newName;

        srl.serverInfo[i].key = class'o_Utility'.static.ParseTags(displayedServerDetails[j].keyTag) $ srl.serverInfo[i].key;
        srl.serverInfo[i].value = class'o_Utility'.static.ParseTags(displayedServerDetails[j].valTag) $ srl.serverInfo[i].value;
        break;
      }

      if (j == (displayedServerDetails.length - 1))
        srl.serverInfo.remove(i,1);
    }
  }

  // add custom details
  for (i = 0; i < displayedServerDetails.length; i++)
  {
    if (displayedServerDetails[i].bCustom == true)
    {
      srl.serverInfo.length = srl.serverInfo.length + 1;
      srl.serverInfo[srl.serverInfo.length - 1].key = class'o_Utility'.static.ParseTags(displayedServerDetails[i].keyTag) $ displayedServerDetails[i].name;
      srl.serverInfo[srl.serverInfo.length - 1].value = class'o_Utility'.static.ParseTags(displayedServerDetails[i].valTag) $ displayedServerDetails[i].customValue;
    }
  }
}


// shows some information in the server's name in real time
// such as wave number, zeds left and so on
// depends on current state of the game
function dynamicChangeServerName()
{
  local string infoBlock;
  local string currentState;
  local int i;

  // if infoBlock is used in the server name (and stateAnalyzer was succesfully loaded)
  if (bInfoBlockInServerName && stateAnalyzer != none)
  {
    // get the game state from custom state analyzer
    // for example: WAVE/TRADER/WIPE/CHANGING_MAP
    currentState = stateAnalyzer.getState();

    // get appropriate infoBlock pattern for current game state
    // and then replace %shitLikeThis% with real values
    for (i = 0; i < infoBlockPatterns.length; i++)		
      if (currentState == infoBlockPatterns[i].state)
      {
        infoBlock = fillInfoBlock(infoBlockPatterns[i].pattern);
        break;
      }

    // paste infoBlock in server name
    if (inStr(serverName, "%infoBlock%") != -1)
      srl.serverName = repl(serverName, "%infoBlock%", infoBlock);
    // can't find %infoBlock% in the server's name, so past infoBlock at the end
    else
      srl.serverName = serverName@infoBlock;
  }
  // infoBlock isn't used in the server name
  else
    srl.serverName = serverName;

  // color everything at this step
  srl.serverName = class'o_Utility'.static.ParseTags(srl.serverName);
}


// function which replaces %keysLikeThis% in the "infoBlock" with real values
function string fillInfoBlock(string parsedInfoBlock)
{
  local int i;
  local int j;

  // searching for server admin's custom keys in the "infoBlock pattern"
  for (i = 0; i < infoBlockKeys.length; i++)
  {
    // in case it's in the "infoBlock pattern", start search in server details
    // to past its value in place of %someDefinedKey%
    if (inStr(parsedInfoBlock, "%"$infoBlockKeys[i].key$"%") != -1)
      for (j = 0; j < srl.serverInfo.length; j++)
      {
        if (srl.serverInfo[j].key == infoBlockKeys[i].detail)
          parsedInfoBlock = repl(parsedInfoBlock, "%"$infoBlockKeys[i].key$"%", srl.serverInfo[j].value);
      }
  }
  return parsedInfoBlock;
}


// it's changed function of TWI 'GameInfo'.GetServerPlayers() with some extended capabilities
// just adds list of players
function GetServerPlayers()
{
  local Mutator m;
  local Controller c;
  local PlayerReplicationInfo pri;
  local int i, teamFlag[2];

  i = srl.playerInfo.length;

  if (!bAnotherNicknamesStyle)
  {
    teamFlag[0] = 1 << 29;
    teamFlag[1] = teamFlag[0] << 1;		
  }

  for (c = level.controllerList; c != none; c = c.nextController)
  {
    pri = c.playerReplicationInfo;
    if ((pri != none) && !pri.bBot && MessagingSpectator(c) == None)
    {
      srl.playerInfo.length = i + 1;
      srl.playerInfo[i].playerNum  = c.playerNum;
      srl.playerInfo[i].score      = pri.score;
      srl.playerInfo[i].ping       = 4 * pri.Ping;

      if (bAnotherNicknamesStyle)
      {
        srl.playerInfo[i].statsID = 0;
        if (c.isInState('Spectating'))
          srl.playerInfo[i].playerName = repl(playerSpectatingNicknamePattern, "%nickname%", pri.playerName);
        else if (c.isInState('Dead') || (c.isInState('GameEnded') && c.playerReplicationInfo.bOutOfLives) || c.isInState('WaitingForPawn'))
          srl.playerInfo[i].playerName = repl(playerDeadNicknamePattern, "%nickname%", pri.playerName);
        else if (c.isInState('PlayerWaiting'))
          srl.playerInfo[i].playerName = repl(playerAwaitingNicknamePattern, "%nickname%", pri.playerName);
        else
          srl.playerInfo[i].playerName = repl(playerAliveNicknamePattern, "%nickname%", pri.playerName); //@c.GetStateName()
      }
      else if (level.game.bTeamGame && pri.team != none)
      {
        srl.playerInfo[i].statsID = srl.playerInfo[i].statsID | teamFlag[pri.Team.TeamIndex];				
        srl.playerInfo[i].playerName = pri.playerName;
      }

      if (bColorNicknames)
        colorNicknames(srl.playerInfo[i].playerName);

      i++;
    }
  }

  // Ask the mutators if they have anything to add.
  for (m = level.game.baseMutator.nextMutator; m != none; m = m.nextMutator)
    m.getServerPlayers(srl);
}


// colors were imported from ScrnBalanceSrv (C)PooSH
// replace color tags with real colors
function colorNicknames(out string nickname)
{
  nickname = class'o_Utility'.static.ParseTags(nickname);
}


// ==========================================================================
defaultproperties
{
  refreshTime=3
}