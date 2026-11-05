@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Affected Object'
@Metadata.allowExtensions: true

@UI.headerInfo: { typeName: 'Affected Object',
                  typeNamePlural: 'Affected Objects',
                  title: { type: #STANDARD, value: 'ExternalProcessedObjectID' } }

// Navigation to the processed object app (intent, see ZI_PRC_LatestHeaderMessage): the
// column is ProcessedObjectUUID (semantic key of the target, bound to UUID) with the
// external ID as its text - Fiori Elements only passes fields the table loads, a hidden
// UUID would not arrive. The creation data of the step is renamed so it is not taken
// as creation data of the object.
define view entity ZC_PRC_ObjectForMessageTP
  as projection on ZR_PRC_ObjectForMessageTP
{
  key StepUUID,

      @ObjectModel.text.element: [ 'ExternalProcessedObjectID' ]
      ProcessedObjectUUID,
      ExternalProcessedObjectID,
      ProcessName,
      StartState,
      EndState,
      MessageText,
      MessageClass,
      MessageNumber,
      MessageSeverity,
      MessageVariable1,
      MessageVariable2,
      MessageVariable3,
      MessageVariable4,
      MessageSeverityCode,
      CreatedBy as StepCreatedBy,
      CreatedAt as StepCreatedAt,

      _Message : redirected to parent ZC_PRC_MessageTP
}
