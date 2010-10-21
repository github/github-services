class Yammer::User
  extend Forwardable 
  def_delegator :@user, :id

  def initialize(mash, client)
    @user   = mash
    @client = client 
  end

  def me?
    @user.id == @client.me.id
  end

  def method_missing(call, *args)
    @user.send(call, *args)
  end
end
