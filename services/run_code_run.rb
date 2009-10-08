service :run_code_run do |data, payload|
  runcoderun_url = URI.parse("http://runcoderun.com/github")
  Net::HTTP.post_form(runcoderun_url, :payload => JSON.generate(payload))
  "this output here to make the Sinatra happy when testing a GitHub service, biznatch!"
end
