// base gamerule class for our mod
class base_GR extends GameRules;


var protected string GameTypeName; // cache gametype name for further use

// pre defined gametype consts
const KFGameType="KFMod.KFGameType";
const KFStoryGame="KFStoryGame.KFStoryGameInfo";

var protected KFGameType kfgt;
var protected KFStoryGameInfo kfstory;
var protected KF_StoryGRI kfstory_GRI;


// ==========================================================================
//                           GAMERULE REGISTRATION
// ==========================================================================

event PostBeginPlay()
{
    if (Level.Game.GameRulesModifiers == none)
        Level.Game.GameRulesModifiers = self;
    else
        Level.Game.GameRulesModifiers.AddGameRules(self);
}


function AddGameRules(GameRules GR)
{
    if (GR != self)
        super.AddGameRules(GR);
}


// ==========================================================================
//                                  STARTUP
// ==========================================================================

event PreBeginPlay()
{
  super.PreBeginPlay();

  // set this at spawn time
  GameTypeName = getGTstr();

  // set gametype vars
  // vanilla kf
  if (ClassIsChildOf(level.game.class, class'KFGameType'))
    kfgt = KFGameType(level.game);
  else
    log(">>> WARNING!!! KFGameType was not found.", class.name);

  // vanilla KFO
  if (ClassIsChildOf(level.game.class, class'KFStoryGameInfo'))
  {
    kfstory = KFStoryGameInfo(level.game);
    kfstory_GRI = KF_StoryGRI(kfstory.GameReplicationInfo);
  }
}


final function string getGTstr()
{
  local GameReplicationInfo tempGri;

  foreach allActors(class'GameReplicationInfo', tempGri)
  {
    return tempGri.gameClass;
  }
}


// ==========================================================================
//                                SHUT DOWN
// ==========================================================================

// keep everything clean and safe
event Destroyed()
{
  super.Destroyed();

  kfgt = none;
  kfstory = none;
  kfstory_GRI = none;
}

// ==========================================================================
//                                FUNCTIONS
// ==========================================================================

// class'GameInfo'.static.AddServerDetails(); copy-cat
final static function addSD(out GameInfo.serverResponseLine serverState, string newkey, coerce string newvalue)
{
  class'GameInfo'.static.AddServerDetail(serverState, newkey, newvalue);
}


// ==========================================================================
// func stubs
function string getState();


// ==========================================================================
defaultproperties{}