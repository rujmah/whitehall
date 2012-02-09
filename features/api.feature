Feature: The API
In order to be able to build exciting new things using our data
A developer
Should be able to make calls to a simple REST/JSON API 

@wip
Scenario: Retrieving a list of organisations
  Given the organisation "Attorney General's Office" exists
  When I make an API call to "/government/api/organisations.json"
  Then I should receive a list of organisations in JSON including "Attorney General's Office"

Scenario: Organisation response should show documents
  Given the organisation "Attorney General's Office" contains some policies
  And other organisations also have policies
  When I visit the "Attorney General's Office" organisation
  Then I should only see published policies belonging to the "Attorney General's Office" organisation

Scenario: Organisation response contains multiple agencies
  Given that "BIS" is responsible for "Companies House" and "UKTI"
  When I visit the "BIS" organisation
  Then I should see that "BIS" is responsible for "Companies House"
  And I should see that "BIS" is responsible for "UKTI"