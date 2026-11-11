"! <p class="shorttext synchronized">Unit of work failed - signal only, carries no data</p>
"!
"! Raised as soon as the unit of work is known to have failed. Deliberately
"! empty: all messages of the step live in the message handler, so there is
"! exactly one source of truth for the log.
"!
"! Only the message handler raises it (CREATE PRIVATE, friend): a step fails
"! only through the handler, so it always has an error message. Transitions
"! and tests may catch it and let it pass on.
CLASS zcx_prc_unit_of_work_failed DEFINITION
  PUBLIC INHERITING FROM cx_static_check FINAL CREATE PRIVATE
  GLOBAL FRIENDS zcl_prc_message_handler.
protected section.
private section.
ENDCLASS.



CLASS ZCX_PRC_UNIT_OF_WORK_FAILED IMPLEMENTATION.
ENDCLASS.
