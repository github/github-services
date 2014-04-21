class Service::TestTrack < Service::HttpPost
  string :server_url, :issue_tag, :test_case_tag, :requirement_tag
  password :provider_key

  white_list :server_url, :issue_tag, :test_case_tag, :requirement_tag

  url 'http://www.seapine.com'
  maintained_by :github => 'seapine'
  supported_by :github => 'seapine'

  def receive_push
    server_url = required_config_value('server_url')
    required_config_value('provider_key')

    ['issue_tag', 'test_case_tag', 'requirement_tag'].each do |tag_name|
      tag = data[tag_name].to_s
      type_name = tag_name.sub('_tag', '').gsub('_', ' ').split.map(&:capitalize).join(' ')

      # []- are forbidden in the tag
      if tag.match(/[\[\]-]/) != nil
        raise_config_error "Invalid #{type_name} tag"
      end
    end

    url = "#{server_url}?action=AddGitHubAttachment"
    res = deliver url
    check_response(res)
  end

  def check_response(res)
    if res.status == 200
      res_json = JSON.parse(res.body)
      if res_json['errorCode'] != 0
        raise_config_error res_json['errorMessage']
      end
    else
      raise_config_error "Unexpected response code: #{res.status}"
    end
  end
end

