service :web_translate_it do |data, payload|
  wti_url = URI.parse("https://webtranslateit.com/api/projects/#{data['api_key']}/refresh_files")
  Net::HTTP.post_form(wti_url, :payload => JSON.generate(payload))
end
