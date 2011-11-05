require "media_wiki"
class Service::MWAPI < Service
  string :url, :user, :title
  password :pass
  # A MediaWiki hook. Given the URL to the MediaWiki install's API, a page name, a user name and a password to the user, will post a commit log on the wiki.
  def receive_push
    # The line we add looks like: <msg> <commit URL>
    line_add = "\n* #{summary_message}: #{summary_url}"
    # Log in to the install.
    mw = MediaWiki::Gateway.new(data['url'])
    mw.login(data['user'], data['pass'])
    # Good. Fetch page if it exists somehow.
    page_text = mw.get(data['title'])
    if page_text == nil
      mw.create(data['title'], ' ', :summary => 'Creating page -- did not exist during push')
    end
    # Append our line to the end of the page_text
    page_text << line_add
    # Save the page
    mw.edit(data['title'], page_text, :summary => 'Updated commits upon push')
  end
end
