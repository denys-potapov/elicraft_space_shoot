import * as Blockly from "blockly";

Blockly.Blocks["sprite_handler"] = {
  init() {
    this.appendDummyInput()
      .appendField("on")
      .appendField(
        new Blockly.FieldDropdown([["handle_tick", "handle_tick"]]),
        "EVENT"
      );
    this.appendStatementInput("BODY").setCheck(null);
    this.setColour(160);
    this.setTooltip("Sprite event handler");
    this.setMovable(false);
    this.setDeletable(false);
  },
};

Blockly.Blocks["sprite_action"] = {
  init() {
    this.appendDummyInput()
      .appendField(
        new Blockly.FieldDropdown([
          ["move left", "move_left"],
          ["move right", "move_right"],
          ["move up", "move_up"],
          ["move down", "move_down"],
        ]),
        "ACTION"
      )
      .appendField("by")
      .appendField(new Blockly.FieldNumber(4, 0), "AMOUNT");
    this.setPreviousStatement(true, null);
    this.setNextStatement(true, null);
    this.setColour(230);
    this.setTooltip("Move the sprite");
  },
};
