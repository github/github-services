service :jaconda do |data, payload|
  throw(:halt, 400) if data['api_token'].to_s == '' || data['room_id'].to_s == ''

  repository = CGI.escapeHTML(payload['repository']['name'])
  branch = CGI.escapeHTML(payload['ref_name'])
  commits = payload['commits']
  api_token = data['api_token']
  room_id = data['room_id']
  url = URI.parse("http://#{api_token}:X@jaconda.im/api/rooms/#{room_id}/messages.json")

  before, after = payload['before'][0..6], payload['after'][0..6]
  compare_url = payload['repository']['url'] + "/compare/#{before}...#{after}"

  if data['digest'].to_i == 1 && commits.size > 1
    commit = commits.first
    message = "<i>Commit <a href='#{commit["url"]}'>#{commit["id"][0..6]}</a> on #{repository}/#{branch} by #{CGI.escapeHTML(commit["author"]["name"])}</i><br /><br />"
    message += CGI.escapeHTML(commit["message"])
    message += "<br /><br /><i>(+#{commits.size - 1} <a href='#{compare_url}'>more commits</a>)</i>"

    res = Net::HTTP.post_form(url, {:text => message})
    throw(:halt, [res.code.to_i, res.body.to_s]) unless res.is_a?(Net::HTTPSuccess)
  else
    commits.each do |commit|
      message = "<i>Commit <a href='#{commit["url"]}'>#{commit["id"][0..6]}</a> on #{repository}/#{branch} by #{CGI.escapeHTML(commit["author"]["name"])}</i><br /><br />"
      message += CGI.escapeHTML(commit["message"])

      res = Net::HTTP.post_form(url, {:text => message})
      throw(:halt, [res.code.to_i, res.body.to_s]) unless res.is_a?(Net::HTTPSuccess)
    end
  end
  true
end