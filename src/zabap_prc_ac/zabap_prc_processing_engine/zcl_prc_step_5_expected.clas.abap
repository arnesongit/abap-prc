"! <p class="shorttext synchronized">ABAP-PRC: Step layer 5 - expected errors</p>
"!
"! Catches business errors - from the transition, the simulation or the commit,
"! all signalled by ZCX_PRC_UNIT_OF_WORK_FAILED. Rolls back, chooses the step
"! header with ZCL_PRC_STEP_HEADER=>FOR_FAILURE - the failure message of the
"! transition, else the last error - and writes the failed step with all
"! messages of the handler and the next retry data in a new LUW.
CLASS zcl_prc_step_5_expected DEFINITION PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_prc_processing_step.

    METHODS constructor IMPORTING i_inner       TYPE REF TO zif_prc_processing_step
                                  i_step_writer TYPE REF TO zcl_prc_step_writer.

  PROTECTED SECTION.
  PRIVATE SECTION.
    DATA mo_inner       TYPE REF TO zif_prc_processing_step.
    DATA mo_step_writer TYPE REF TO zcl_prc_step_writer.
ENDCLASS.



CLASS zcl_prc_step_5_expected IMPLEMENTATION.

  METHOD constructor.
    mo_inner       = i_inner.
    mo_step_writer = i_step_writer.
  ENDMETHOD.


  METHOD zif_prc_processing_step~execute.
    TRY.
        r_state = mo_inner->execute( EXPORTING i_state           = i_state
                                               i_message_handler = i_message_handler
                                     IMPORTING e_transition      = e_transition ).

      CATCH zcx_prc_unit_of_work_failed.
        " ROLLBACK ENTITIES rolls back nothing without a RAP buffer (e.g. a pure BAPI
        " process). ROLLBACK WORK discards registered update function modules and
        " the SQL of the result layer in every case.
        ROLLBACK ENTITIES.
        ROLLBACK WORK.

        " The transition is unbound if it could not be instantiated
        DATA(header) = zcl_prc_step_header=>for_failure(
                           i_message_handler = i_message_handler
                           i_failure_message = COND #( WHEN e_transition IS BOUND
                                                       THEN e_transition->get_failure_message( ) ) ).

        " The state before the step, only the retry data change
        r_state = mo_step_writer->write( i_start_state     = i_state-State
                                         i_state           = mo_step_writer->with_next_retry( i_state )
                                         i_header          = header
                                         i_message_handler = i_message_handler ).
        " The RAP buffer is empty after the rollback, so COMMIT ENTITIES alone
        " would not commit the step written by SQL
        COMMIT ENTITIES.
        COMMIT WORK.
    ENDTRY.
  ENDMETHOD.

ENDCLASS.
