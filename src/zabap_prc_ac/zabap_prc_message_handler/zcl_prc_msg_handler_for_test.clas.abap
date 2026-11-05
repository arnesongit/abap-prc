"! <p class="shorttext synchronized">Message handler for tests</p>
"! For tests only: creates a fresh message handler, e.g. to call a transition
"! handler directly or to test the handler itself. In productive code the
"! engine creates the handler and passes it to the transition handler.
CLASS zcl_prc_msg_handler_for_test DEFINITION
  PUBLIC
  FINAL
  CREATE PRIVATE
  FOR TESTING.

  PUBLIC SECTION.
    "! Creates a fresh, empty handler
    "! @parameter r_message_handler | New handler
    CLASS-METHODS create RETURNING VALUE(r_message_handler) TYPE REF TO zif_prc_message_handler.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_prc_msg_handler_for_test IMPLEMENTATION.

  METHOD create.
    r_message_handler = zcl_prc_message_handler=>create_message_handler( ).
  ENDMETHOD.

ENDCLASS.
