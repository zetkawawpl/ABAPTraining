CLASS lhc_Z00_R_TRAVEL DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_i_authorizations FOR INSTANCE AUTHORIZATION
      keys REQUEST requested_authorizations FOR Travel RESULT result.

    METHODS get_g_authorizations FOR GLOBAL AUTHORIZATION
      REQUEST requested_authorizations FOR Travel RESULT result.

    METHODS cancel_travel FOR MODIFY
       keys FOR ACTION Travel~cancel_travel.

    METHODS validateDescription FOR VALIDATE ON SAVE
       keys FOR Travel~validateDescription.

    METHODS validateCustomer FOR VALIDATE ON SAVE
       keys FOR Travel~validateCustomer.

    METHODS determineStatus FOR DETERMINE ON MODIFY
       keys FOR Travel~determineStatus.

    METHODS validateBeginDate FOR VALIDATE ON SAVE
       keys FOR Travel~validateBeginDate.

    METHODS validateDateSequence FOR VALIDATE ON SAVE
       keys FOR Travel~validateDateSequence.

    METHODS validateEndDate FOR VALIDATE ON SAVE
       keys FOR Travel~validateEndDate.

    METHODS get_instance_features FOR INSTANCE FEATURES
      keys REQUEST requested_features FOR Travel RESULT result.
    METHODS determineduration FOR DETERMINE ON SAVE
       keys FOR travel~determineduration.

    METHODS earlynumbering_create FOR NUMBERING
       entities FOR CREATE Travel.

ENDCLASS.

CLASS lhc_Z00_R_TRAVEL IMPLEMENTATION.

  METHOD get_i_authorizations.

    result = CORRESPONDING #( keys ).

    LOOP AT result ASSIGNING FIELD-SYMBOL(<result>).

      DATA(rc) =  /lrn/cl_s4d437_model=>authority_check(
                                          i_agencyid  = <result>-agencyid
                                          i_actvt     = '02' ).

      IF rc <> 0.
        <result>-%action-cancel_travel = if_abap_behv=>auth-unauthorized.
        <result>-%update               = if_abap_behv=>auth-unauthorized.
        <result>-%delete               = if_abap_behv=>auth-unauthorized.
      ELSE.
        <result>-%action-cancel_travel = if_abap_behv=>auth-allowed.
        <result>-%update               = if_abap_behv=>auth-allowed.
      ENDIF.

    ENDLOOP.

  ENDMETHOD.

  METHOD get_g_authorizations.
  ENDMETHOD.

  METHOD cancel_travel.

    READ ENTITIES OF Z00_R_Travel IN LOCAL MODE
        ENTITY travel
        ALL FIELDS WITH CORRESPONDING #( keys )
        RESULT DATA(travels).

    LOOP AT travels INTO DATA(travel).
      IF travel-status <> 'C'.
        MODIFY ENTITIES OF Z00_R_Travel IN LOCAL MODE
           ENTITY travel
               UPDATE FIELDS ( status )
               WITH VALUE #( ( %tky   = travel-%tky
                               status = 'C' ) ).
      ELSE.
        APPEND VALUE #( %tky = travel-%tky ) TO failed-travel.
        APPEND VALUE #( %tky = travel-%tky
                        %msg = NEW /lrn/cm_s4d437(
                                    textid = /lrn/cm_s4d437=>already_canceled ) )
            TO reported-travel.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.

  METHOD validateDescription.

    CONSTANTS c_area TYPE string VALUE `DESC`.

    READ ENTITIES OF Z00_R_Travel IN LOCAL MODE
        ENTITY Travel
            FIELDS ( Description )
            WITH CORRESPONDING #( keys )
            RESULT DATA(travels).

    LOOP AT travels ASSIGNING FIELD-SYMBOL(<travel>).

      APPEND VALUE #( %tky = <travel>-%tky
                      %state_area = c_area )
          TO reported-travel.

      IF <travel>-Description IS INITIAL.
        APPEND VALUE #( %tky = <travel>-%tky )
            TO failed-travel.

        APPEND VALUE #( %tky = <travel>-%tky
                        %msg = NEW /lrn/cm_s4d437( /lrn/cm_s4d437=>field_empty )
                        %element-Description = if_abap_behv=>mk-on
                        %state_area = c_area )
            TO reported-travel.

      ENDIF.

    ENDLOOP.

  ENDMETHOD.

  METHOD validateCustomer.

    CONSTANTS c_area TYPE string VALUE `CUST`.

    READ ENTITIES OF Z00_R_Travel IN LOCAL MODE
       ENTITY Travel
           FIELDS ( CustomerId )
           WITH CORRESPONDING #( keys )
           RESULT DATA(travels).

    LOOP AT travels ASSIGNING FIELD-SYMBOL(<travel>).

      APPEND VALUE #( %tky = <travel>-%tky
                  %state_area = c_area )
      TO reported-travel.

      IF <travel>-CustomerId IS INITIAL.
        APPEND VALUE #( %tky = <travel>-%tky )
            TO failed-travel.

        APPEND VALUE #( %tky = <travel>-%tky
                        %msg = NEW /lrn/cm_s4d437( /lrn/cm_s4d437=>field_empty )
                        %element-CustomerId = if_abap_behv=>mk-on
                        %state_area = c_area )
            TO reported-travel.

      ELSE.
        SELECT SINGLE
          FROM /dmo/i_customer
        FIELDS CustomerID
         WHERE CustomerID = @<travel>-CustomerId
          INTO @DATA(dummy).

        IF sy-subrc <> 0.
          APPEND VALUE #( %tky = <travel>-%tky )
              TO failed-travel.

          APPEND VALUE #( %tky = <travel>-%tky
                          %msg = NEW /lrn/cm_s4d437( textid = /lrn/cm_s4d437=>customer_not_exist
                                                     customerid = <travel>-CustomerId )
                          %element-CustomerId = if_abap_behv=>mk-on
                          %state_area = c_area )
             TO reported-travel.
        ENDIF.

      ENDIF.
    ENDLOOP.

  ENDMETHOD.

  METHOD earlynumbering_create.

    mapped-travel = CORRESPONDING #( entities ).

    LOOP AT mapped-travel ASSIGNING FIELD-SYMBOL(<mapping>).
      <mapping>-AgencyId = /lrn/cl_s4d437_model=>get_agency_by_user( sy-uname ).
      <mapping>-TravelId = /lrn/cl_s4d437_model=>get_next_travelid( ).
    ENDLOOP.

  ENDMETHOD.

  METHOD determineStatus.

    READ ENTITIES OF Z00_R_Travel IN LOCAL MODE
      ENTITY Travel
      FIELDS ( Status )
      WITH CORRESPONDING #( keys )
      RESULT DATA(travels).

    DELETE travels WHERE Status IS NOT INITIAL.
    CHECK travels IS NOT INITIAL.

    MODIFY ENTITIES OF Z00_R_Travel IN LOCAL MODE
        ENTITY Travel
        UPDATE FIELDS ( Status )
        WITH VALUE #( FOR key IN travels ( %tky = key-%tky
                                           Status = 'N' ) )
        REPORTED DATA(update_reported).

    reported = CORRESPONDING #( DEEP update_reported ).

  ENDMETHOD.

  METHOD validateBeginDate.

    READ ENTITIES OF Z00_r_travel IN LOCAL MODE
      ENTITY travel
      FIELDS ( begindate )
      WITH CORRESPONDING #( keys )
      RESULT DATA(travels).

    LOOP AT travels ASSIGNING FIELD-SYMBOL(<travel>).

      IF <travel>-begindate IS INITIAL.

        APPEND VALUE #(  %tky = <travel>-%tky )
            TO failed-travel.

        APPEND VALUE #( %tky = <travel>-%tky
                        %msg = NEW /lrn/cm_s4d437(
                                     /lrn/cm_s4d437=>field_empty
                                   )
                        %element-begindate = if_abap_behv=>mk-on
                       )
            TO reported-travel.
      ELSEIF <travel>-begindate < cl_abap_context_info=>get_system_date(  ).

        APPEND VALUE #(  %tky = <travel>-%tky )
            TO failed-travel.

        APPEND VALUE #( %tky = <travel>-%tky
                        %msg = NEW /lrn/cm_s4d437(
                                     textid     = /lrn/cm_s4d437=>begin_date_past
                                   )
                        %element-begindate = if_abap_behv=>mk-on
                       )
        TO reported-travel.

      ENDIF.
    ENDLOOP.

  ENDMETHOD.

  METHOD validateDateSequence.

    READ ENTITIES OF Z00_r_travel IN LOCAL MODE
    ENTITY travel
    FIELDS ( begindate enddate )
    WITH CORRESPONDING #( keys )
    RESULT DATA(travels).

    LOOP AT travels ASSIGNING FIELD-SYMBOL(<travel>).

      IF <travel>-enddate < <travel>-begindate.
        APPEND VALUE #(  %tky = <travel>-%tky )
           TO failed-travel.
        APPEND VALUE #( %tky = <travel>-%tky
                        %msg = NEW /lrn/cm_s4d437(
                                     /lrn/cm_s4d437=>dates_wrong_sequence
                                   )
                    %element = VALUE #(
                                     begindate = if_abap_behv=>mk-on
                                     enddate   = if_abap_behv=>mk-on
                                    )
                       )
             TO reported-travel.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.

  METHOD validateEndDate.

    READ ENTITIES OF Z00_r_travel IN LOCAL MODE
     ENTITY travel
     FIELDS ( enddate )
     WITH CORRESPONDING #( keys )
     RESULT DATA(travels).

    LOOP AT travels ASSIGNING FIELD-SYMBOL(<travel>).

      IF <travel>-enddate IS INITIAL.

        APPEND VALUE #(  %tky = <travel>-%tky )
            TO failed-travel.

        APPEND VALUE #( %tky = <travel>-%tky
                        %msg = NEW /lrn/cm_s4d437(
                                     /lrn/cm_s4d437=>field_empty
                                   )
                        %element-enddate = if_abap_behv=>mk-on
                       )
            TO reported-travel.
      ELSEIF <travel>-enddate < cl_abap_context_info=>get_system_date(  ).

        APPEND VALUE #(  %tky = <travel>-%tky )
            TO failed-travel.

        APPEND VALUE #( %tky = <travel>-%tky
                        %msg = NEW /lrn/cm_s4d437(
                                     textid     = /lrn/cm_s4d437=>end_date_past
                                   )
                        %element-enddate = if_abap_behv=>mk-on
                      )
        TO reported-travel.

      ENDIF.
    ENDLOOP.

  ENDMETHOD.

  METHOD get_instance_features.

    READ ENTITIES OF Z00_R_Travel IN LOCAL MODE
       ENTITY Travel
       FIELDS ( Status BeginDate EndDate )
       WITH CORRESPONDING #( keys )
       RESULT DATA(travels).

    LOOP AT travels ASSIGNING FIELD-SYMBOL(<travel>).
      APPEND CORRESPONDING #( <travel> ) TO result ASSIGNING FIELD-SYMBOL(<result>).

      IF <travel>-%is_draft = if_abap_behv=>mk-on.
        READ ENTITIES OF Z00_R_Travel IN LOCAL MODE
          ENTITY Travel
          FIELDS ( BeginDate EndDate )
          WITH VALUE #( ( %key = <travel>-%key
                          %is_draft = if_abap_behv=>mk-off ) )
          RESULT DATA(travels_active).

        IF travels_active IS NOT INITIAL.
          <travel>-BeginDate = travels_active[ 1 ]-BeginDate.
          <travel>-EndDate   = travels_active[ 1 ]-EndDate.
        ELSE.
          CLEAR <travel>-BeginDate.
          CLEAR <travel>-EndDate.
        ENDIF.

*        IF lines( travels_active ) GT 0.
*        IF line_exists( travels_active[ 1 ] )

      ENDIF.

      IF <travel>-Status = 'C' OR
       ( <travel>-EndDate IS NOT INITIAL AND
         <travel>-EndDate < cl_abap_context_info=>get_system_date( ) ).

        <result>-%update = if_abap_behv=>fc-o-disabled.
        <result>-%action-cancel_travel = if_abap_behv=>fc-o-disabled.

      ELSE.

        <result>-%update = if_abap_behv=>fc-o-enabled.
        <result>-%action-cancel_travel = if_abap_behv=>fc-o-enabled.

      ENDIF.

      IF <travel>-BeginDate IS NOT INITIAL AND
         <travel>-BeginDate < cl_abap_context_info=>get_system_date( ).

        <result>-%field-CustomerId = if_abap_behv=>fc-f-read_only.
        <result>-%field-BeginDate = if_abap_behv=>fc-f-read_only.

      ELSE.

        <result>-%field-CustomerId = if_abap_behv=>fc-f-mandatory.
        <result>-%field-BeginDate = if_abap_behv=>fc-f-mandatory.

      ENDIF.


    ENDLOOP.

  ENDMETHOD.

  METHOD determineDuration.

    READ ENTITIES OF Z00_R_Travel IN LOCAL MODE
    ENTITY Travel
    FIELDS ( BeginDate EndDate )
    WITH CORRESPONDING #( keys )
    RESULT DATA(travels).

    LOOP AT travels ASSIGNING FIELD-SYMBOL(<travel>).
      <travel>-Duration = <travel>-EndDate - <travel>-BeginDate.
    ENDLOOP.

    MODIFY ENTITIES OF Z00_R_Travel IN LOCAL MODE
        ENTITY Travel
        UPDATE FIELDS ( Duration )
        WITH CORRESPONDING #( travels ).

  ENDMETHOD.

ENDCLASS.
