enum CommandName {
  UNDO,
  REDO,
  FORECOLOR,
  BACKCOLOR,
  FONTNAME,
  FONTSIZE,
  BOLD,
  ITALIC,
  UNDERLINE,
  SUBSCRIPT,
  SUPERSCRIPT,
  STRIKETHROUGH,
  FORMATBLOCK, // passes value for below format
  H1,
  H2,
  H3,
  H4,
  H5,
  H6,
  P,
  PRE,
  BR, // not settable (at least i don't know how)
  BLOCKQUOTE,
  REMOVEFORMAT,
  JUSTIFYCENTER,
  JUSTIFYFULL,
  JUSTIFYLEFT,
  JUSTIFYRIGHT,
  INDENT,
  OUTDENT,
  INSERTUNORDEREDLIST,
  INSERTORDEREDLIST,
  INSERTHORIZONTALRULE,
  INSERTHTML, // determines if the three command below are executable
  INSERTLINK, // pseudo commands, there are no corresponding values for execCommand()
  INSERTIMAGE,
  INSERTCHECKBOX,
// pseudo commands for toggling grouped command views
  ENTER_VIEWING_MODE,
  EXPANDING_SEARCH_VIEWING,
  TOGGLE_GROUPED_TEXT_STYLES_COMMANDS_VIEW,
  TOGGLE_GROUPED_INSERT_COMMANDS_COMMANDS_VIEW
}

enum BarPosition {TOP, BOTTOM}
