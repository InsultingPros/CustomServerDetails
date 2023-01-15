# Custom Server Details

[![GitHub all releases](https://img.shields.io/github/downloads/InsultingPros/CustomServerDetails/total)](https://github.com/InsultingPros/CustomServerDetails/releases)

Allows to color, rename, edit other server infos, print game states (aka WIPE, WIN, LOBBY, etc) and players states (DEAD, SPECTATING, etc). And you can add your own haiku's / custom key-infos.

> **N.B.** `Killingfloor.ini` -> [Engine.GameReplicationInfo] -> ServerName: set your NON colored server name here, to avoid weird characters in Steam server browser / gametrackers.

## Installation

```cpp
`KillingFloor.ini`
[Engine.GameEngine]
;ServerActors=IpDrv.MasterServerUplink
ServerActors=CustomServerDetails.CSDMasterServerUplink
```

## Building and Dependancies

At the moment of 2021.03.27 there are no dependencies.

Use [KF Compile Tool](https://github.com/InsultingPros/KFCompileTool) for easy compilation.

```cpp
EditPackages=CustomServerDetails
```

## Config Files

Define your custom tags and add them in `infoblocks`. Just check the [CustomServerDetails.ini](Configs/CustomServerDetails.ini 'main config') for reference.

For default `serverinfo` keys:

![img](Docs/Default_KF_Keys.png)

## Steam workshop

<https://steamcommunity.com/sharedfiles/filedetails/?id=2463978063>
