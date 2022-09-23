class CSDMasterServerUplink extends MasterServerUplink
    config(CustomServerDetails);


// ==========================================================================
// variables

// To understand what's going on here, just look at sample .ini file. It's very simple.
struct displayedDetails
{
    var string name;        // name of the key
    var string keyTag;      // color tag of key (name)
    var string valTag;      // color tag of value
    var bool   bChangeName; // change name of the key
    var string newName;     // new name
    var bool   bCustom;     // if true, set name and customValue (and ofc their colors)
    var string customValue;
};

struct infoBlockPattern
{
    var string state;
    var string pattern;
};

struct cacheinfoBlockPattern
{
    var string state;
    var string pattern;
    var bool   bPasteValue;
};

struct infoBlockKey
{
    var string detail;
    var string key;
};

var config bool                         bChangeServerDetails;     // if true, you can filter/change/add server details
var config array<displayedDetails>      displayedServerDetails;   // server details you want to show
var config int                          refreshTime;              // [seconds] how frequently refresh and send informaton to master server
var config bool                         bCustomServerName;        // allows you to use custom server name
var config string                       serverName;               // obviously
var config bool                         bMapColor;                // obviously
var config string                       mapColor;                 // obviously
var config bool                         bInfoBlockInServerName;   //if true, adds block with information in the server's name, there must be %infoBlock% in the "serverName"
var config array<infoBlockPattern>      infoBlockPatterns;        //there is unique name of the server for every state of the game
var config array<infoBlockKey>          infoBlockKeys; //custom %keys%, which are used in the "infoBlock", so some server details can be showed in the server's name
var config bool                         bAnotherNicknamesStyle; //if true, you can define the style of nicknames, depends on state of the player (dead, spectating etc.)
var config string                       playerDeadNicknamePattern; //style of player's nickname when he is dead. must consists %nickname%
var config string                       playerSpectatingNicknamePattern;//same, but for spectating state
var config string                       playerAwaitingNicknamePattern; //same
var config string                       playerAliveNicknamePattern; //same
var config bool                         bColorNicknames; //change color keys (like ^2 or ^6) to real colors


var private GameInfo.serverResponseLine srl;
var private AdditionalServerDetails AdditionalSD;

// caching to reduce high resource usage
var private transient bool bInit;
var private transient string cachedColoredMapName;
var private transient array<GameInfo.KeyValuePair> cachedServerInfo;
var private transient array<cacheinfoBlockPattern> cachedInfoBlockPatterns;

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
//                                STARTUP
// ==========================================================================
event postBeginPlay()
{
    // add to the game special custom GameRules
    // so these GameRules will add extra details on the server description
    if (AdditionalSD == none)
        AdditionalSD = spawn(class'AdditionalServerDetails');

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

    // ConsoleCommand("PROFILESCRIPT START");
    // start the timer with config delay
    setTimer(refreshTime, true);
}


final private function CacheStuff()
{
    local int i, n;
    local cacheinfoBlockPattern ibp;

    ServerName = class'o_Utility'.static.ParseTags(ServerName);
    // pre color everything
    for (i = 0; i < infoBlockPatterns.length; i++)
    {
        ibp.state = infoBlockPatterns[i].state;
        ibp.pattern = class'o_Utility'.static.ParseTags(infoBlockPatterns[i].pattern);
        cachedInfoBlockPatterns[cachedInfoBlockPatterns.Length] = ibp;
    }

    // create separate, smaller array of value containing patterns
    for (i = 0; i < cachedInfoBlockPatterns.length; i++)
    {
        for (n = 0; n < infoBlockKeys.length; n++)
        {
            if (inStr(cachedInfoBlockPatterns[i].pattern, "%"$infoBlockKeys[n].key$"%") != -1)
            {
                cachedInfoBlockPatterns[i].bPasteValue = true;
            }
        }
    }


    // filter/add/change server details
    if (bChangeServerDetails)
    {
        filterServerDetails();
    }

    if (bMapColor)
    {
        cachedColoredMapName = class'o_Utility'.static.ParseTags(mapColor $ srl.mapName);
        srl.mapName = cachedColoredMapName;
    }

    cachedServerInfo = srl.ServerInfo;
    serverState = srl;

    bInit = true;
}


// ==========================================================================
//                            TIMER and FUNCTIONS
// ==========================================================================

// DISABLE original getter / 60 sec timer
event Refresh(){}


// set our Timer
event timer()
{
    // uncomment if you want to measure whole mod impact in performance
    // local float f;
    // Clock(f);

    // ask server for all iformation it can give
    level.game.getServerInfo(srl);
    getServerPlayers();
    level.game.getServerDetails(srl);

    if (!bInit)
        CacheStuff();
    else
    {
        // change server name to custom one
        if (bCustomServerName)
            dynamicChangeServerName();

        if (bMapColor)
            srl.mapName = cachedColoredMapName;

        srl.ServerInfo = cachedServerInfo;
        serverState = srl;
    }

    // uncomment if you want to measure whole mod impact in performance
    // UnClock(f);
    // log("Timer() job done in - "@f);
}


// it's changed function of TWI 'GameInfo'.GetServerPlayers() with some extended capabilities
// just adds list of players
final private function GetServerPlayers()
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
                srl.playerInfo[i].playerName = repl(getCtrlState(c), "%nickname%", pri.playerName);
            }
            else if (level.game.bTeamGame && pri.team != none)
            {
                srl.playerInfo[i].statsID = srl.playerInfo[i].statsID | teamFlag[pri.Team.TeamIndex];
                srl.playerInfo[i].playerName = pri.playerName;
            }

            // parse and color nicknames
            if (bColorNicknames)
            {
                srl.playerInfo[i].playerName = class'o_Utility'.static.ParseTags(srl.playerInfo[i].playerName);
            }

            i++;
        }
    }

    // Ask the mutators if they have anything to add.
    for (m = level.game.baseMutator.nextMutator; m != none; m = m.nextMutator)
        m.getServerPlayers(srl);
}


final private function string getCtrlState(Controller c)
{
    // c.GetStateName()
    if (c.isInState('Spectating'))
        return playerSpectatingNicknamePattern;
    else if (c.isInState('Dead') || (c.isInState('GameEnded') && c.playerReplicationInfo.bOutOfLives) || c.isInState('WaitingForPawn'))
        return playerDeadNicknamePattern;
    else if (c.isInState('PlayerWaiting'))
        return playerAwaitingNicknamePattern;
    else
        return playerAliveNicknamePattern;
}


// shows some information in the server's name in real time
// such as wave number, zeds left and so on
// depends on current state of the game
final private function dynamicChangeServerName()
{
    local string infoBlock;
    local string currentState;
    local int i;

    // if infoBlock is used in the server name (and stateAnalyzer was succesfully loaded)
    if (bInfoBlockInServerName)
    {
        // get the game state from custom state analyzer
        // for example: WAVE/TRADER/WIPE/CHANGING_MAP
        currentState = AdditionalSD.getState();

        // get appropriate infoBlock pattern for current game state
        // and then replace %shitLikeThis% with real values
        for (i = 0; i < cachedInfoBlockPatterns.length; i++)
        {
            if (currentState == cachedInfoBlockPatterns[i].state)
            {
                infoBlock = fillInfoBlock(cachedInfoBlockPatterns[i].pattern, cachedInfoBlockPatterns[i].bPasteValue);
                break;
            }
        }

        // paste infoBlock in server name
        if (inStr(serverName, "%infoBlock%") != -1)
            srl.serverName = repl(serverName, "%infoBlock%", infoBlock);
        // can't find %infoBlock% in the server's name, so past infoBlock at the end
        else
            srl.serverName = serverName @ infoBlock;
    }
    // infoBlock isn't used in the server name
    else
        srl.serverName = serverName;
}


// function which replaces %keysLikeThis% in the "infoBlock" with real values
final private function string fillInfoBlock(string parsedInfoBlock, optional bool bPasteValue)
{
    local int i;
    local int j;

    if (bPasteValue)
    {
        // searching for server admin's custom keys in the "infoBlock pattern"
        for (i = 0; i < infoBlockKeys.length; i++)
        {
            // in case it's in the "infoBlock pattern", start search in server details
            // to past its value in place of %someDefinedKey%
            if (inStr(parsedInfoBlock, "%"$infoBlockKeys[i].key$"%") != -1)
            {
                for (j = 0; j < srl.serverInfo.length; j++)
                {
                    if (srl.serverInfo[j].key == infoBlockKeys[i].detail)
                        parsedInfoBlock = repl(parsedInfoBlock, "%"$infoBlockKeys[i].key$"%", srl.serverInfo[j].value);
                }
            }
        }
    }
    return parsedInfoBlock;
}


// color / change server details in bottom left
// slowest function in our entire mod, update it once per 60 sec
final private function filterServerDetails()
{
    local int i, j;
    // local float f;

    // Clock(f);
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
    // UnClock(f);
    // log("part one:"@f);
    // f = 0.0;

    // Clock(f);
    // add custom details
    for (i = 0; i < displayedServerDetails.length; i++)
    {
        if (displayedServerDetails[i].bCustom)
        {
            AdditionalSD.addSD(srl, class'o_Utility'.static.ParseTags(displayedServerDetails[i].keyTag) $ displayedServerDetails[i].name,
                            class'o_Utility'.static.ParseTags(displayedServerDetails[i].valTag) $ displayedServerDetails[i].customValue);
        }
    }

    // UnClock(f);
    // log("part two:"@f);
}


// ==========================================================================
defaultproperties
{
    refreshTime=4
}