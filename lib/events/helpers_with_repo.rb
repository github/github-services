module Service::HelpersWithRepo
  def repo
    @repo ||= self.class.objectify(payload['repository'])
  end
end
