When /^I make an API call to "([^"]*)"$/ do |path|
  visit path
end

Then /^I should receive a list of organisations in JSON including "([^"]*)"$/ do |organisation_name|
  assert_equal 'application/json', page.response_headers['Content-Type'].split(';').first
  result = JSON.parse(page.source)
  assert_equal 'ok', result['response']['status']
  assert result['response']['results'].detect { |result| result['name'] == organisation_name }
end

Then /^I should receive a JSON response for the "([^"]*)" organisation$/ do |organisation_name|
  assert_equal 'application/json', page.response_headers['Content-Type'].split(';').first
  result = JSON.parse(page.source)

  assert_equal 'ok', result['response']['status']
  assert_equal organisation_name, result['response']['content']['name']
end

Then /^I should see policies included in the contents$/ do
  result = JSON.parse(page.source)
  assert result['response']['contents'].detect { |result| result['type'] == 'policy' }
end