CLASS zcl_prc_demo_adj_run_proc DEFINITION
  PUBLIC FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_prc_process.

    ALIASES tt_transition FOR zif_prc_process~tt_transition.
    ALIASES ty_state      FOR zif_prc_process~ty_state.

    CONSTANTS co_class_name     TYPE zprc_process_impl_class VALUE 'ZCL_PRC_DEMO_ADJ_RUN_PROC'.
    CONSTANTS co_process_name   TYPE zprc_process_name       VALUE 'SRV_CTR_ADJ_RUN'.

ENDCLASS.


CLASS zcl_prc_demo_adj_run_proc IMPLEMENTATION.
  METHOD zif_prc_process~get_transitions.
    rt_transitions = VALUE tt_transition( ( start_state = zif_prc_process~co_start  end_state = zif_prc_process~co_finished ) ).
  ENDMETHOD.

  METHOD zif_prc_process~get_transition_handler.
    CASE i_start_state.
      WHEN zif_prc_process~co_start.
        ro_transition_handler = NEW lcl_adjust( ).
      WHEN OTHERS.
        " unexpected state
        ASSERT 1 = 2.
    ENDCASE.
  ENDMETHOD.

  METHOD zif_prc_process~get_url_for_processed_object.
    select single uuid from zprc_demo_srvctr
      where service_contract_id = @iv_processed_object
      into @data(l_uuid).
    cl_system_uuid=>convert_uuid_x16_static( EXPORTING uuid     = l_uuid
                                             IMPORTING
*                                                       uuid_c22 =
*                                                       uuid_c32 =
*                                                       uuid_c26 =
                                                       uuid_c36 = DATA(ls) ).
*  CATCH cx_uuid_error.'
    RETURN |#ABAP_PRC_Demo_ServiceContract-show&/ServiceContract({ to_lower( ls ) })?layout=MidColumnFullScreen|.
  ENDMETHOD.
ENDCLASS.
