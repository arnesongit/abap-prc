"! <p class="shorttext synchronized">ABAP-PRC: Step layer 3 - write result</p>
"!
"! Decides what is persisted after a successful transition: new state, payload,
"! retry reset, the step, all messages of the handler and the step header.
"! Writes within the running LUW, the commit is the next layer.
"!
"! The step header is chosen here, where success is known (the save
"! simulation passed), by ZCL_PRC_STEP_HEADER=>FOR_SUCCESS. It is handed to the
"! step writer only, not to the message handler: it reaches the persistence
"! with the commit of the step. If the commit fails, it is rolled back with
"! the step and does not show up among the messages of the failed step.
CLASS zcl_prc_step_3_result DEFINITION PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_prc_processing_step.

    METHODS constructor IMPORTING i_inner       TYPE REF TO zif_prc_processing_step
                                  i_step_writer TYPE REF TO zcl_prc_step_writer.

  PROTECTED SECTION.
  PRIVATE SECTION.
    DATA mo_inner       TYPE REF TO zif_prc_processing_step.
    DATA mo_step_writer TYPE REF TO zcl_prc_step_writer.
ENDCLASS.



CLASS zcl_prc_step_3_result IMPLEMENTATION.

  METHOD constructor.
    mo_inner       = i_inner.
    mo_step_writer = i_step_writer.
  ENDMETHOD.


  METHOD zif_prc_processing_step~execute.
    r_state = mo_inner->execute( EXPORTING i_state           = i_state
                                           i_message_handler = i_message_handler
                                 IMPORTING e_transition      = e_transition ).

    DATA(header) = zcl_prc_step_header=>for_success( i_transition      = e_transition
                                                     i_message_handler = i_message_handler ).

    r_state = mo_step_writer->write( i_start_state     = i_state-State
                                     i_state           = VALUE #( BASE r_state
                                                                  RetryCount    = 0
                                                                  RetryDateTime = 0 )
                                     i_header          = header
                                     i_message_handler = i_message_handler ).
  ENDMETHOD.

ENDCLASS.
