service :runcoderun do |data, payload|
  runcoderun_url = URI.parse("http://runcoderun.com/github")
  Net::HTTP.post_form(runcoderun_url, payload)
end
