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


// ==========================================================================
// main function that colors strings from user defined tags / color structs
// converts color tags to colors
final static function string ParseTags(string input)
{
  local int i;

  for (i = 0; i < default.ColorList.Length; i++)
  {
    ReplaceText(input, default.ColorList[i].Tag, class'GameInfo'.static.MakeColorCode(default.ColorList[i].Color));
  }
  return input;
}


// remove all user defined tags, aka ^1^, #4#, etc.
final static function string StripTags(string input)
{
  local int i;

  for (i = 0; i < default.ColorList.length; i++)
  {
    ReplaceText(input, default.ColorList[i].tag, "");
  }
  return input;
}


// Engine.GameInfo
// removes colors from a string
final static function string StripColor(string s)
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
final static function string NormalizeText(string input)
{
  input = StripTags(input);
  input = StripColor(input);

  return input;
}


// ==========================================================================
defaultproperties{}