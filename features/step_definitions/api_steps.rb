When /^I make an API call to "([^"]*)"$/ do |path|
  visit path
end

Then /^I should receive a list of organisations in JSON including "([^"]*)"$/ do |organisation_name|
  assert_equal 'application/json', page.response_headers['Content-Type'].split(';').first
  result = JSON.parse(page.source)
  assert_equal 'ok', result['response']['status']
  assert result['response']['results'].detect { |result| result['name'] == organisation_name }
end
