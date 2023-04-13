// Replace vanilla ServerUplink with our fancy one
// Author        : NikC-
// Home Repo     : https://github.com/InsultingPros/CustomServerDetails
// License       : https://www.gnu.org/licenses/gpl-3.0.en.html
class CSDMasterServerUplink extends MasterServerUplink
    config(CustomServerDetails);

// ==========================================================================
// variables

// To understand what's going on here, just look at sample .ini file. It's very simple.
struct displayedDetails {
    var string name;        // name of the key
    var string keyTag;      // color tag of key (name)
    var string valTag;      // color tag of value
    var bool bChangeName;   // change name of the key
    var string newName;     // new name
    var bool bCustom;       // if true, set name and customValue (and ofc their colors)
    var string customValue;
};

struct infoBlockPattern {
    var string state;
    var string pattern;
};

struct cacheinfoBlockPattern {
    var string state;
    var string pattern;
    var bool bPasteValue;
    var array<int> ArrIdxInfoBlockKeys;
    var array<int> ArrIdxSrlKeys;
};

struct infoBlockKey {
    var string detail;
    var string key;
};

// if true, you can filter/change/add server details
var config bool bChangeServerDetails;
// server details you want to show
var config array<displayedDetails> displayedServerDetails;
// [seconds] how frequently refresh and send informaton to master server
var config int refreshTime;
// allows you to use custom server name from config file
// obviously
var config bool bCustomServerName;
var config string serverName;
var config bool bMapColor;
var config string mapColor;
// if true, adds block with information in the server's name, there must be %infoBlock% in the "serverName"
var config bool bInfoBlockInServerName;
// there is unique name of the server for every state of the game
var config array<infoBlockPattern> infoBlockPatterns;
// custom %keys%, which are used in the "infoBlock", so some server details can be showed in the server's name
var config array<infoBlockKey> infoBlockKeys;
// if true, you can define the style of nicknames, depends on state of the player (dead, spectating etc.)
var config bool bAnotherNicknamesStyle;
// style of player's nickname when he is dead / awaiting / spectating / alive. Must consists %nickname%
var config string playerDeadNicknamePattern;
var config string playerSpectatingNicknamePattern;
var config string playerAwaitingNicknamePattern;
var config string playerAliveNicknamePattern;
// change color keys (like ^2 or ^6) to real colors
var config bool bColorNicknames;
var config array<string> extendedServerDetailsClassName;

var public GameInfo.serverResponseLine srl;
var public AdditionalServerDetails AdditionalSD;
var public o_Utility _;
var public CacheManager CacheManager;

// variables for caching
// N.B. transient modificator does nothing here, I just
// use it to visually differentiate 'special' variables
var public transient string cachedServerName;
var public transient bool bChangeServerName;
var public transient string cachedColoredMapName;
var public transient array<GameInfo.KeyValuePair> cachedServerInfo;
var public transient array<cacheinfoBlockPattern> cachedInfoBlockPatterns;
var public transient string cachedPlayerDeadNicknamePattern;
var public transient string cachedPlayerSpectatingNicknamePattern;
var public transient string cachedPlayerAwaitingNicknamePattern;
var public transient string cachedPlayerAliveNicknamePattern;

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

// DISABLE original getter
event Refresh() {}

// ==========================================================================
//                                STARTUP
// ==========================================================================
event postBeginPlay() {
    local int i;
    local class<base_GR> additionalGameRule;

    // add custom GameRule for extra details on the server description
    if (AdditionalSD == none) {
        AdditionalSD = spawn(class'AdditionalServerDetails');
    }
    // add to the game special custom GameRules
    // so these GameRules will add extra details on the server description
    for (i = 0; i < extendedServerDetailsClassName.length; i++)
    {
        additionalGameRule = class<base_GR>(dynamicLoadObject(extendedServerDetailsClassName[i], class'class'));

        if (additionalGameRule == none) {
            warn("Class '" $ extendedServerDetailsClassName[i] $ "' (extendedServerDetailsClassName) wasn't found.");
            continue;
        }
        spawn(additionalGameRule);
    }

    // cache everything at this step
    CacheManager.InitCaching(self);
    // start the timer with config delay
    setTimer(refreshTime, true);
    // DEBUG!
    // ConsoleCommand("PROFILESCRIPT START")
}

// ==========================================================================
//                            TIMER and FUNCTIONS
// ==========================================================================

event timer() {
    // local float g, f, y;

    // Clock(g);
    // ask server for all information it can give
    level.game.getServerInfo(srl);
    CSDGetServerPlayers();
    level.game.getServerDetails(srl);
    // UnClock(g);
    // warn("Part #1 done in - " $ g);

    // Clock(f);
    // change server name to custom one / fill %infoblock%
    if (bChangeServerName) {
        dynamicChangeServerName();
    }
    if (bMapColor) {
        srl.mapName = cachedColoredMapName;
    }
    // UnClock(f);
    // warn("Part #2 done in - " $ f);

    // Clock(y);
    // use precached server details
    srl.ServerInfo = cachedServerInfo;
    serverState = srl;
    // UnClock(y);
    // warn("Part #3 done in - " $ y);

    if (level.game.NumPlayers == 0) {
        gotoState('ServerEmpty', 'begin');
    }
}

state ServerEmpty {
    event timer() {
        if (level.game.NumPlayers == 0) {
            return;
        }
        // reset timer to normal rate
        setTimer(refreshTime, true);
        gotoState('');
    }

begin:
    // warn("empty server state started!");
    // scan active players with higher rate
    setTimer(0.5, true);
}

// it's changed function of TWI 'GameInfo'.GetServerPlayers() with some extended capabilities
// just adds list of players
final private function CSDGetServerPlayers() {
    local Mutator m;
    local Controller c;
    local PlayerReplicationInfo pri;
    local GameInfo.PlayerResponseLine locPRL;
    local array<GameInfo.PlayerResponseLine> cachedPlayerRL;
    local int teamFlag[2];

    if (!bAnotherNicknamesStyle) {
        teamFlag[0] = 1 << 29;
        teamFlag[1] = teamFlag[0] << 1;
    }

    for (c = level.controllerList; c != none; c = c.nextController) {
        if (!c.bIsPlayer) {
            continue;
        }

        pri = c.playerReplicationInfo;
        // avoid casting Controller to MessagingSpectator
        // when there is a special bool to check
        if (pri != none && !pri.bBot) {
            locPRL.playerNum = c.playerNum;
            locPRL.score = pri.score;
            locPRL.ping = 4 * pri.Ping;

            if (bAnotherNicknamesStyle) {
                locPRL.statsID = 0;
                locPRL.playerName = repl(getCtrlState(c, pri), "%nickname%", pri.playerName);
            } else if (level.game.bTeamGame && pri.team != none) {
                locPRL.statsID = locPRL.statsID | teamFlag[pri.Team.TeamIndex];
                locPRL.playerName = pri.playerName;
            }

            // parse and color nicknames
            if (bColorNicknames) {
                locPRL.playerName = _.ParseTags(locPRL.playerName);
            }
            cachedPlayerRL[cachedPlayerRL.Length] = locPRL;
        }
    }

    srl.playerInfo = cachedPlayerRL;

    // Ask the mutators if they have anything to add.
    for (m = level.game.baseMutator.nextMutator; m != none; m = m.nextMutator) {
        m.getServerPlayers(srl);
    }
}

final private function string getCtrlState(Controller c, playerReplicationInfo pri) {
    // c.GetStateName()
    // most reliable way to check spectators
    if (pri.bOnlySpectator) {
        return cachedPlayerSpectatingNicknamePattern;
    }
    // if (c.isInState('Spectating'))

    //     return cachedPlayerSpectatingNicknamePattern;
    else if (
        c.isInState('Dead') ||
        (c.isInState('GameEnded') && c.playerReplicationInfo.bOutOfLives) ||
        c.isInState('WaitingForPawn')
    ) {
        return cachedPlayerDeadNicknamePattern;
    } else if (c.isInState('PlayerWaiting')) {
        return cachedPlayerAwaitingNicknamePattern;
    } else {
        return cachedPlayerAliveNicknamePattern;
    }
}

// shows some information in the server's name in real time
// such as wave number, zeds left and so on
// depends on current state of the game
final private function dynamicChangeServerName() {
    if (bInfoBlockInServerName) {
        srl.serverName = repl(cachedServerName, "%infoBlock%", getInfoBlock());
    } else {
        srl.serverName = cachedServerName;
    }
}

// state STRING - cachedinfoblockpatter INT - infoblockkey ARR INT - SRL ARR INT
// #2 slowest function
// function which replaces %keysLikeThis% in the "infoBlock" with real values
final private function string getInfoBlock() {
    local int i, j, n;
    local string sstate, result;

    // avoid function calls, even if we loop 1-2 elements
    sstate = AdditionalSD.getState();
    // log("sstate is: " $ sstate);

    // get appropriate infoBlock pattern for current game state
    // and then replace %shitLikeThis% with real values
    for (i = 0; i < cachedInfoBlockPatterns.length; i++) {
        // get the game state from custom state analyzer
        // for example: WAVE/TRADER/WIPE/CHANGING_MAP
        if (sstate == cachedInfoBlockPatterns[i].state) {
            // fillInfoBlock(cachedInfoBlockPatterns[i].pattern, cachedInfoBlockPatterns[i].bPasteValue);
            result = cachedInfoBlockPatterns[i].pattern;
            // log("BROKE at IDX: " $ i);
            break;
        }
    }

    // PLEASE cache this!
    // srl.serverInfo keys are always sorted the same way
    if (cachedInfoBlockPatterns[i].bPasteValue) {
        // log("i="$i);
        // searching for server admin's custom keys in the "infoBlock pattern"
        for (n = 0; n < infoBlockKeys.length; n++) {
            // in case it's in the "infoBlock pattern", start search in server details
            // to past its value in place of %someDefinedKey%
            if (inStr(result, "%"$infoBlockKeys[n].key$"%") != -1) {
                // log("n="$n);
                for (j = 0; j < srl.serverInfo.length; j++) {
                    if (srl.serverInfo[j].key == infoBlockKeys[n].detail) {
                        // log("j="$j);
                        result = repl(result, "%"$infoBlockKeys[n].key$"%", srl.serverInfo[j].value);
                    }
                }
            }
        }
    }

    return result;
}

// ==========================================================================
defaultproperties {
    refreshTime=4

    // https://wiki.beyondunreal.com/Subobjects
    // quick access objects
    Begin Object Class=o_Utility Name=o_Utility_Instance
    End Object
    _=o_Utility_Instance;

    Begin Object Class=CacheManager Name=CacheManager_Instance
    End Object
    CacheManager=CacheManager_Instance;
}