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
  When I make an API call to "/government/api/organisations/attorney-generals-office.json"
  Then I should receive a JSON response for the "Attorney General's Office" organisation
  And I should see policies included in the contents

# Scenario: Organisation response contains multiple agencies
#   Given that "Attorney General's Office" is responsible for "Companies House" and "UKTI"
#   When I make an API call to "/government/api/organisations/attorney-generals-office.json"
#   Then I should receive a JSON response for the "Attorney General's Office" organisation
#   And I should see "Companies House" as a related item
#
# Scenario: API responses should be traversable
#   Given the organisation "Attorney General's Office" contains some policies
#   When I make an API call to "/government/api/organisations/attorney-generals-office.json"
#   And I follow the api_uri link for the first content item
#   Then I should receive a JSON response for a policy
