class CacheManager extends Object;

const NICKNAME_MATCH="%nickname%";
const NICKNAME_WARNING="CustomServerDetails[WARNING]: You set 'bAnotherNicknamesStyle=true'. But you didn't paste %nickname% in '%var%'. JUST DO IT!";

public final function InitCaching(CSDMasterServerUplink CSDUplink) {
    CheckNicknameStyles(CSDUplink);
    PreCacheServerName(CSDUplink);
    PreCacheNickNamePatterns(CSDUplink);
    PreColorInfoBlockPatterns(CSDUplink);
    FilterInfoBlockPatterns(CSDUplink);

    // ask server for all iformation it can give
    CSDUplink.level.game.getServerInfo(CSDUplink.srl);
    CSDUplink.level.game.getServerDetails(CSDUplink.srl);

    // filter/add/change server details
    if (CSDUplink.bChangeServerDetails) {
        filterServerDetails(CSDUplink);
    }
    if (CSDUplink.bMapColor) {
        CSDUplink.cachedColoredMapName = CSDUplink._.ParseTags(CSDUplink.mapColor $ CSDUplink.srl.mapName);
        CSDUplink.srl.mapName = CSDUplink.cachedColoredMapName;
    }

    CSDUplink.cachedServerInfo = CSDUplink.srl.ServerInfo;
    CSDUplink.serverState = CSDUplink.srl;
}

// check if our settings are ok
// if not - fix automatically with a warning text
public final function CheckNicknameStyles(CSDMasterServerUplink CSDUplink) {
    if (!CSDUplink.bAnotherNicknamesStyle) {
        return;
    }

    if (inStr(CSDUplink.playerDeadNicknamePattern, NICKNAME_MATCH) == -1) {
        log(Repl(NICKNAME_WARNING, "%var%", "playerDeadNicknamePattern"));
        CSDUplink.playerDeadNicknamePattern @= NICKNAME_MATCH;
    }
    if (inStr(CSDUplink.playerSpectatingNicknamePattern, NICKNAME_MATCH) == -1) {
        log(Repl(NICKNAME_WARNING, "%var%", "playerSpectatingNicknamePattern"));
        CSDUplink.playerSpectatingNicknamePattern @= NICKNAME_MATCH;
    }
    if (inStr(CSDUplink.playerAwaitingNicknamePattern, NICKNAME_MATCH) == -1) {
        log(Repl(NICKNAME_WARNING, "%var%", "playerAwaitingNicknamePattern"));
        CSDUplink.playerAwaitingNicknamePattern @= NICKNAME_MATCH;
    }
    if (inStr(CSDUplink.playerAliveNicknamePattern, NICKNAME_MATCH) == -1) {
        log(Repl(NICKNAME_WARNING, "%var%", "playerAliveNicknamePattern"));
        CSDUplink.playerAliveNicknamePattern @= NICKNAME_MATCH;
    }
}

public final function PreCacheNickNamePatterns(CSDMasterServerUplink CSDUplink) {
    CSDUplink.cachedPlayerDeadNicknamePattern = CSDUplink._.ParseTags(CSDUplink.playerDeadNicknamePattern);
    CSDUplink.cachedPlayerSpectatingNicknamePattern = CSDUplink._.ParseTags(CSDUplink.PlayerSpectatingNicknamePattern);
    CSDUplink.cachedPlayerAwaitingNicknamePattern = CSDUplink._.ParseTags(CSDUplink.playerAwaitingNicknamePattern);
    CSDUplink.cachedPlayerAliveNicknamePattern = CSDUplink._.ParseTags(CSDUplink.playerAliveNicknamePattern);
}

public final function PreCacheServerName(CSDMasterServerUplink CSDUplink) {
    if (CSDUplink.bCustomServerName) {
        CSDUplink.cachedServerName = CSDUplink._.ParseTags(CSDUplink.ServerName);
    } else {
        CSDUplink.cachedServerName = CSDUplink.Level.GRI.ServerName;
    }

    if (CSDUplink.bInfoBlockInServerName) {
        // can't find %infoBlock% in the server's name, so past infoBlock at the end
        if (inStr(CSDUplink.cachedServerName, "%infoBlock%") == -1) {
            log("CustomServerDetails[WARNING]: You set 'bInfoBlockInServerName=true'. But you didn't paste %infoBlock% in Server Name. JUST DO IT!");
            CSDUplink.cachedServerName @= "%infoBlock%";
        }
    } else {
        // find the %infoBlock% and remove it
        if (inStr(CSDUplink.cachedServerName, "%infoBlock%") != -1) {
            log("CustomServerDetails[WARNING]: You set 'bInfoBlockInServerName=false'. But you paste %infoBlock% in Server Name. REMOVE IT!");
            CSDUplink.cachedServerName -= "%infoBlock%";
        }
    }

    // less boolean checks in main Timer()
    if (CSDUplink.bInfoBlockInServerName || CSDUplink.bCustomServerName) {
        CSDUplink.bChangeServerName = true;
    }
}

// parse tags and create cached array of colored strings
// to avoid expensive function calls on every use
public final function PreColorInfoBlockPatterns(CSDMasterServerUplink CSDUplink) {
    local int i;
    local CSDMasterServerUplink.cacheinfoBlockPattern ibp;

    for (i = 0; i < CSDUplink.infoBlockPatterns.length; i++) {
        ibp.state = CSDUplink.infoBlockPatterns[i].state;
        ibp.pattern = CSDUplink._.ParseTags(CSDUplink.infoBlockPatterns[i].pattern);
        CSDUplink.cachedInfoBlockPatterns[CSDUplink.cachedInfoBlockPatterns.Length] = ibp;
    }
}

public final function FilterInfoBlockPatterns(CSDMasterServerUplink CSDUplink) {
    local int i, n;

    // filter InfoBlockPatterns that require key replacing
    for (i = 0; i < CSDUplink.cachedInfoBlockPatterns.length; i++) {
        for (n = 0; n < CSDUplink.infoBlockKeys.length; n++) {
            if (
                inStr(
                    CSDUplink.cachedInfoBlockPatterns[i].pattern,
                    "%" $ CSDUplink.infoBlockKeys[n].key $ "%"
                ) != -1
            ) {
                CSDUplink.cachedInfoBlockPatterns[i].bPasteValue = true;
                // !!!
                break;
            }
        }
    }
}

// color / change server details in bottom left
// #1 slowest function in our entire mod
public final function filterServerDetails(CSDMasterServerUplink CSDUplink) {
    local int i, j;
    // local float f, y;

    // CSDUplink.Clock(f);
    // delete all details that are not in allowed list
    // change detail names if necessary, add color
    for (i = CSDUplink.srl.serverInfo.length - 1; i >= 0; i--) {
        for (j = 0; j < CSDUplink.displayedServerDetails.length; j++) {
            if (
                CSDUplink.srl.serverInfo[i].key ~= CSDUplink.displayedServerDetails[j].name &&
                !CSDUplink.displayedServerDetails[j].bCustom
            ) {
                if (CSDUplink.displayedServerDetails[j].bChangeName) {
                    CSDUplink.srl.serverInfo[i].key = CSDUplink.displayedServerDetails[j].newName;
                }

                CSDUplink.srl.serverInfo[i].key = CSDUplink._.ParseTags(CSDUplink.displayedServerDetails[j].keyTag) $ CSDUplink.srl.serverInfo[i].key;
                CSDUplink.srl.serverInfo[i].value = CSDUplink._.ParseTags(CSDUplink.displayedServerDetails[j].valTag) $ CSDUplink.srl.serverInfo[i].value;
                break;
            }

            if (j == (CSDUplink.displayedServerDetails.length - 1)) {
                CSDUplink.srl.serverInfo.remove(i,1);
            }
        }
    }
    // CSDUplink.UnClock(f);
    // warn("part one:" @ f);

    // CSDUplink.Clock(y);
    // add custom details
    for (i = 0; i < CSDUplink.displayedServerDetails.length; i++) {
        if (CSDUplink.displayedServerDetails[i].bCustom) {
            CSDUplink.AdditionalSD.addSD(
                CSDUplink.srl,
                CSDUplink._.ParseTags(CSDUplink.displayedServerDetails[i].keyTag) $ CSDUplink.displayedServerDetails[i].name,
                CSDUplink._.ParseTags(CSDUplink.displayedServerDetails[i].valTag) $ CSDUplink.displayedServerDetails[i].customValue
            );
        }
    }

    // CSDUplink.UnClock(y);
    // warn("part two:" @ y);
}