Feature: The API
In order to be able to build exciting new things using our data
A developer
Should be able to make calls to a simple REST/JSON API 

Scenario: Retrieving a list of organisations
  Given the organisation "Attorney General's Office" exists
  When I make an API call to "/government/api/organisations.json"
  Then I should receive a list of organisations in JSON including "Attorney General's Office"

Scenario: Organisation response should show documents
  Given the organisation "Attorney General's Office" contains some policies
  When I make an API call to "/government/api/organisations/1.json"
  Then I should receive a JSON response for the "Attorney General's Office" organisation
  And I should see policies included in the contents

@wip
Scenario: Organisation response contains multiple agencies
  Given that "BIS" is responsible for "Companies House" and "UKTI"
  When I visit the "BIS" organisation
  Then I should see that "BIS" is responsible for "Companies House"
  And I should see that "BIS" is responsible for "UKTI"

@wip
Scenario: API responses should be traversable
