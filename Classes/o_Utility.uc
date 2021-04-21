class o_Utility extends Object
  config(CustomServerDetails);


// ==========================================================================
// variables

// used to create colored string array
var transient bool bInitialize;
var string msg_error;

struct ColorStruct
{
  var config string Name, Tag;
  var config color Color;
};
var config array<ColorStruct> colorList;

// stores converted color codes
var array<string> colorCodes;


// ==========================================================================
// main function that colors strings from user defined tags / color structs 
static final function string ParseTags(string input)
{
  local int i;

  // fill our array at first call, and keep using it
  // to avoid unnecessary function calls 
  if (!default.bInitialize)
  {
    if (default.colorList.length == 0)
    {
      log(default.msg_error);
      return default.msg_error;
    }
    for (i = 0; i < default.colorList.length; i++)
    {
      default.colorCodes[default.colorCodes.length] = GetColorCode(default.colorList[i].color);
    }
    default.bInitialize = true;
  }

  for (i = 0; i < default.colorList.length; i++)
  {
    ReplaceText(input, default.colorList[i].tag, default.colorCodes[i]);
  }
  return input;
}


// remove all user defined tags, aka ^1, #4, ^red, etc.
static final function string StripTags(string input)
{
  local int i;

  for (i=0; i<default.colorList.length; i++)
  {
    ReplaceText(input, default.colorList[i].tag, "");
  }
  return input;
}


// remove color from already colored string
static final function string StripColor(string input)
{
  local int i;

  i = InStr(input, chr(27));
  while (i >= 0)
  {
    input = left(input, i) $ mid(input, i + 4);
    i = InStr(input, Chr(27));
  }
  return input;
}


// remove both tags and colors
static final function string NormalizeText(string input)
{
  input = StripTags(input);
  input = StripColor(input);

  return input;
}


// converts the strings to a color, and the color to a color code
static final function string GetColorCode(color colorToUse)
{
  local byte R, G, B;

  // we don't want to use 0, really
  R = clamp(colorToUse.R, 1, 255);
  G = clamp(colorToUse.G, 1, 255);
  B = clamp(colorToUse.B, 1, 255);

  return Chr(27) $ Chr(R) $ Chr(G) $ Chr(B);
}


// ==========================================================================
defaultproperties
{
  msg_error=">  CustomServerDetails --> o_Utility --> ParseTags(): color struct is empty, check your config!!"
}