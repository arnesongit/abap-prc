"! <p class="shorttext synchronized">Standard implementation of ZIF_PRC_MESSAGE_HANDLER</p>
"!
"! One instance per unit of work. Not reusable after being sealed.
"!
"! Severities: W, I and S are kept. Everything else (E, A, X, ...) is treated
"! and stored as error E, see NORMALIZE_SEVERITY.
CLASS zcl_prc_message_handler DEFINITION PUBLIC FINAL CREATE PRIVATE.

  PUBLIC SECTION.
    INTERFACES zif_prc_message_handler.

    CLASS-METHODS create_message_handler IMPORTING i_bali_log               TYPE REF TO if_bali_log OPTIONAL
                                         RETURNING VALUE(r_message_handler) TYPE REF TO zif_prc_message_handler.

  PRIVATE SECTION.
    METHODS constructor IMPORTING i_bali_log TYPE REF TO if_bali_log.

    DATA ms_header            TYPE zif_prc_message_handler=>ty_message_details.
    DATA mt_messages          TYPE zif_prc_message_handler=>tt_messages.
    DATA mv_failed            TYPE abap_bool.
    DATA mv_already_simulated TYPE abap_bool.

    "! Marks the unit of work as failed, seals the handler and raises.
    "!
    "! @raising zcx_prc_unit_of_work_failed | Always.
    METHODS fail               RAISING   zcx_prc_unit_of_work_failed.
    METHODS append_message     IMPORTING i_message  TYPE symsg.
    METHODS append_messages    IMPORTING i_messages TYPE zcl_prc_message_mapper=>tt_messages.
    METHODS set_message_header IMPORTING i_header   TYPE symsg.

    "! Internal severity of a message: W, I and S are kept, everything else
    "! (E, A, X, ...) becomes E. Used for every message entering the handler,
    "! so all errors are stored and evaluated in the same way.
    "!
    "! @parameter i_msgty | Severity as delivered by the caller.
    "! @parameter r_msgty | W, I, S or E.
    METHODS normalize_severity IMPORTING i_msgty        TYPE symsgty
                               RETURNING VALUE(r_msgty) TYPE symsgty.

    DATA m_bali_log           TYPE REF TO if_bali_log.
    DATA m_log_message_prefix TYPE symsg.
ENDCLASS.


CLASS zcl_prc_message_handler IMPLEMENTATION.
  METHOD append_message.
    APPEND CORRESPONDING #( i_message ) TO mt_messages ASSIGNING FIELD-SYMBOL(<fs>).
    <fs>-msgty = normalize_severity( <fs>-msgty ).

    MESSAGE ID <fs>-msgid
            TYPE <fs>-msgty
            NUMBER <fs>-msgno
            WITH <fs>-msgv1
                 <fs>-msgv2
                 <fs>-msgv3
                 <fs>-msgv4
            INTO <fs>-message_text.

    IF m_log_message_prefix-msgid IS NOT INITIAL.
      MESSAGE ID m_log_message_prefix-msgid
              TYPE m_log_message_prefix-msgty
              NUMBER m_log_message_prefix-msgno
              WITH m_log_message_prefix-msgv1
                   m_log_message_prefix-msgv2
                   m_log_message_prefix-msgv3
                   m_log_message_prefix-msgv4
              INTO <fs>-log_message_prefix.
    ENDIF.

    IF ms_header IS INITIAL OR ms_header-msgid <> 'E'.
      ms_header = <fs>.
    ENDIF.
  ENDMETHOD.

  METHOD append_messages.
    LOOP AT i_messages INTO DATA(ls_message).
      append_message( ls_message ).
    ENDLOOP.
  ENDMETHOD.

  METHOD constructor.
    m_bali_log = i_bali_log.
  ENDMETHOD.

  METHOD create_message_handler.
    r_message_handler = NEW zcl_prc_message_handler( i_bali_log ).
  ENDMETHOD.

  METHOD fail.
    mv_failed = abap_true.
    RAISE EXCEPTION NEW zcx_prc_unit_of_work_failed( ).
  ENDMETHOD.

  METHOD normalize_severity.
    r_msgty = COND #( WHEN i_msgty = 'W' OR i_msgty = 'I' OR i_msgty = 'S'
                      THEN i_msgty
                      ELSE 'E' ).
  ENDMETHOD.

  METHOD set_message_header.
    ms_header = CORRESPONDING #( i_header ).
    ms_header-msgty = normalize_severity( ms_header-msgty ).

    MESSAGE ID ms_header-msgid
            TYPE ms_header-msgty
            NUMBER ms_header-msgno
            WITH ms_header-msgv1
                 ms_header-msgv2
                 ms_header-msgv3
                 ms_header-msgv4
            INTO ms_header-message_text.

    IF m_log_message_prefix-msgid IS NOT INITIAL.
      MESSAGE ID m_log_message_prefix-msgid
              TYPE m_log_message_prefix-msgty
              NUMBER m_log_message_prefix-msgno
              WITH m_log_message_prefix-msgv1
                   m_log_message_prefix-msgv2
                   m_log_message_prefix-msgv3
                   m_log_message_prefix-msgv4
              INTO ms_header-log_message_prefix.
    ENDIF.
    APPEND ms_header TO mt_messages.
  ENDMETHOD.

  METHOD zif_prc_message_handler~add_bapi_result.
    r_message_handler = me.

    DATA(lt_msg) = zcl_prc_message_mapper=>from_bapiret( i_bapiret ).
    LOOP AT lt_msg ASSIGNING FIELD-SYMBOL(<ls_msg>).
      <ls_msg>-msgty = normalize_severity( <ls_msg>-msgty ).
    ENDLOOP.
    append_messages( lt_msg ).
    IF i_fail_on_error_message = abap_true AND line_exists( lt_msg[ msgty = 'E' ] ).
      fail( ).
    ENDIF.
  ENDMETHOD.

  METHOD zif_prc_message_handler~add_EML_modify_result.
    r_message_handler = me.

    IF i_reported IS SUPPLIED.
      DATA(lt_msg) = zcl_prc_message_mapper=>from_reported( i_reported ).
      LOOP AT lt_msg ASSIGNING FIELD-SYMBOL(<ls_msg>).
        <ls_msg>-msgty = normalize_severity( <ls_msg>-msgty ).
      ENDLOOP.
      append_messages( lt_msg ).
      IF i_fail_on_error_message = abap_true AND line_exists( lt_msg[ msgty = 'E' ] ).
        fail( ).
      ENDIF.
    ENDIF.

    IF i_failed IS SUPPLIED AND zcl_prc_message_mapper=>is_failed( i_failed ) = abap_true.
      fail( ).
    ENDIF.
  ENDMETHOD.

  METHOD zif_prc_message_handler~add_message_from_sy.
    r_message_handler = me.

    DATA(ls_msg) = CORRESPONDING symsg( sy ).
    ls_msg-msgty = normalize_severity( ls_msg-msgty ).
    append_message( ls_msg ).
    IF i_fail_on_error_message = abap_true AND ls_msg-msgty = 'E'.
      fail( ).
    ENDIF.
  ENDMETHOD.

  METHOD zif_prc_message_handler~add_message_from_text.
    r_message_handler = me.

    DATA(ls_msg) = zcl_prc_message_mapper=>from_text( text  = i_message_text
                                                      msgty = i_message_severity ).
    ls_msg-msgty = normalize_severity( ls_msg-msgty ).
    append_message( ls_msg ).
    IF i_fail_on_error_message = abap_true AND ls_msg-msgty = 'E'.
      fail( ).
    ENDIF.
  ENDMETHOD.

  METHOD zif_prc_message_handler~close_failed.
    set_message_header( CORRESPONDING #( sy ) ).
    fail( ).
  ENDMETHOD.

  METHOD zif_prc_message_handler~finalize_and_persist_log.
    LOOP AT mt_messages INTO DATA(ls_message).
      m_bali_log->add_item( cl_bali_free_text_setter=>create(
                                severity = ls_message-msgty
                                text     = CONV #( |{ ls_message-log_message_prefix } { ls_message-message_text }| ) ) ).
    ENDLOOP.
    cl_bali_log_db=>get_instance( )->save_log_2nd_db_connection( log                        = m_bali_log
                                                                 assign_to_current_appl_job = abap_true ).
  ENDMETHOD.

  METHOD zif_prc_message_handler~get_header.
    r_message = ms_header.
  ENDMETHOD.

  METHOD zif_prc_message_handler~get_messages.
    r_messages = mt_messages.
  ENDMETHOD.

  METHOD zif_prc_message_handler~has_errors.
    r_has_errors = mv_failed.
  ENDMETHOD.

  METHOD zif_prc_message_handler~set_failure_header.
    r_message_handler = me.
    set_message_header( i_header_message ).
  ENDMETHOD.

  METHOD zif_prc_message_handler~set_log_message_prefix.
    m_log_message_prefix = i_log_message_prefix.
  ENDMETHOD.

  METHOD zif_prc_message_handler~set_success_header.
    set_message_header( i_header_message ).
  ENDMETHOD.

  METHOD zif_prc_message_handler~simulate_save.
    r_message_handler = me.

    IF mv_already_simulated = abap_true.
      RAISE EXCEPTION NEW zcx_prc_message_handler_misuse( textid = zcx_prc_message_handler_misuse=>already_simulated ).
    ENDIF.
    mv_already_simulated = abap_true.

    COMMIT ENTITIES IN SIMULATION MODE
           RESPONSES
           FAILED   DATA(lt_failed)
           REPORTED DATA(lt_reported).
    DATA(lv_subrc_bad) = xsdbool( sy-subrc <> 0 ).

    zif_prc_message_handler~add_EML_modify_result( i_failed   = lt_failed
                                                   i_reported = lt_reported ).
    IF lv_subrc_bad = abap_true.
      fail( ).
    ENDIF.
  ENDMETHOD.
ENDCLASS.
