// Contains some utilitary functions
// Author        : NikC-
// Home Repo     : https://github.com/InsultingPros/CustomServerDetails
// License       : https://www.gnu.org/licenses/gpl-3.0.en.html
class o_Utility extends object
    config(CustomServerDetails);


// ==========================================================================
struct ColorRecord
{
    var string Name;    // color name, for comfort
    var string Tag;     // color tag
    var color Color;    // RGBA values
};
var config array<ColorRecord> ColorList;    // color list

// caching
var private transient bool bInit;
var private transient array<string> cachedTags;
var private transient array<string> cachedColoredStrings;

// ==========================================================================
// main function that colors strings from user defined tags / color structs
// converts color tags to colors
final private function Init()
{
    local int i;

    if (!bInit)
    {
        for (i = 0; i < ColorList.Length; i++)
        {
            cachedTags[i] = ColorList[i].Tag;
            cachedColoredStrings[i] = class'GameInfo'.static.MakeColorCode(ColorList[i].Color);
        }
        bInit = true;
        // log(">>>>>>>>>> All tags and colored strings cached!");
    }
}

final function string ParseTags(string input)
{
    local int i;

    if (!bInit)
        Init();

    for (i = 0; i < ColorList.Length; i++)
    {
        ReplaceText(input, cachedTags[i], cachedColoredStrings[i]);
    }
    return input;
}


// remove all user defined tags, aka ^1^, #4#, etc.
final function string StripTags(string input)
{
    local int i;

    for (i = 0; i < ColorList.length; i++)
    {
        ReplaceText(input, ColorList[i].tag, "");
    }
    return input;
}


// Engine.GameInfo
// removes colors from a string
final function string StripColor(string s)
{
    local int p;

    p = InStr(s, chr(27));

    while (p >= 0)
    {
        s = left(s, p) $ mid(S, p + 4);
        p = InStr(s, Chr(27));
    }
    return s;
}


// remove both tags and colors
final function string NormalizeText(string input)
{
    input = StripTags(input);
    input = StripColor(input);

    return input;
}


// ==========================================================================
defaultproperties{}