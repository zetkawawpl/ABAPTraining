@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Projection View'
@Metadata.ignorePropagatedAnnotations: true
@Metadata.allowExtensions: true
@Search.searchable: true
define root view entity Z00_C_TRAVEL
  provider contract transactional_query
  as projection on Z00_R_TRAVEL
{
  key AgencyId,
  key TravelId,
      @Search.defaultSearchElement: true
      @Search.fuzzinessThreshold: 0.7
      Description,
      @Search.defaultSearchElement: true
      @Consumption.valueHelpDefinition: [
        { entity: { name:    '/DMO/I_Customer_StdVH',
                    element: 'CustomerID' } } ]
      CustomerId,
      BeginDate,
      EndDate,
      @EndUserText.label: 'Duration (days)'
      Duration,
      Status,
      ChangedAt,
      ChangedBy,
      LocChangedAt
}
