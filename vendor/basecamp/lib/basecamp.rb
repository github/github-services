# the following are all standard ruby libraries
require 'net/https'
require 'yaml'
require 'date'
require 'time'

begin
  require 'xmlsimple'
rescue LoadError
  begin
    require 'rubygems'
    gem 'xml-simple'
  rescue LoadError
    abort <<-ERROR
The 'xml-simple' library could not be loaded. If you have RubyGems installed
you can install xml-simple by doing "gem install xml-simple".
ERROR
  end
end

# An interface to the Basecamp web-services API. Usage is straightforward:
#
#   session = Basecamp.new('your.basecamp.com', 'username', 'password')
#   puts "projects: #{session.projects.length}"
class Basecamp
  
  # A wrapper to encapsulate the data returned by Basecamp, for easier access.
  class Record #:nodoc:
    attr_reader :type

    def initialize(type, hash)
      @type = type
      @hash = hash
    end

    def [](name)
      name = dashify(name)
      case @hash[name]
        when Hash then 
          @hash[name] = (@hash[name].keys.length == 1 && Array === @hash[name].values.first) ?
            @hash[name].values.first.map { |v| Record.new(@hash[name].keys.first, v) } :
            Record.new(name, @hash[name])
        else @hash[name]
      end
    end

    def id
      @hash["id"]
    end

    def attributes
      @hash.keys
    end

    def respond_to?(sym)
      super || @hash.has_key?(dashify(sym))
    end

    def method_missing(sym, *args)
      if args.empty? && !block_given? && respond_to?(sym)
        self[sym]
      else
        super
      end
    end

    def to_s
      "\#<Record(#{@type}) #{@hash.inspect[1..-2]}>"
    end

    def inspect
      to_s
    end

    private

      def dashify(name)
        name.to_s.tr("_", "-")
      end
  end

  # A wrapper to represent a file that should be uploaded. This is used so that
  # the form/multi-part encoder knows when to encode a field as a file, versus
  # when to encode it as a simple field.
  class FileUpload
    attr_reader :filename, :content
    
    def initialize(filename, content)
      @filename = filename
      @content = content
    end
  end

  attr_accessor :use_xml

  # Connects
  def initialize(url, user_name, password, use_ssl = false)
    @use_xml = false
    @user_name, @password = user_name, password
    connect!(url, use_ssl)
  end

  # Return the list of all accessible projects.
  def projects
    records "project", "/project/list"
  end

  # Returns the list of message categories for the given project
  def message_categories(project_id)
    records "post-category", "/projects/#{project_id}/post_categories"
  end

  # Returns the list of file categories for the given project
  def file_categories(project_id)
    records "attachment-category", "/projects/#{project_id}/attachment_categories"
  end

  # Return information for the company with the given id
  def company(id)
    record "/contacts/company/#{id}"
  end

  # Return an array of the people in the given company. If the project-id is
  # given, only people who have access to the given project will be returned.
  def people(company_id, project_id=nil)
    url = project_id ? "/projects/#{project_id}" : ""
    url << "/contacts/people/#{company_id}"
    records "person", url
  end

  # Return information about the person with the given id
  def person(id)
    record "/contacts/person/#{id}"
  end

  # Return information about the message(s) with the given id(s). The API
  # limits you to requesting 25 messages at a time, so if you need to get more
  # than that, you'll need to do it in multiple requests.
  def message(*ids)
    result = records("post", "/msg/get/#{ids.join(",")}")
    result.length == 1 ? result.first : result
  end

  # Returns a summary of all messages in the given project (and category, if
  # specified). The summary is simply the title and category of the message,
  # as well as the number of attachments (if any).
  def message_list(project_id, category_id=nil)
    url = "/projects/#{project_id}/msg"
    url << "/cat/#{category_id}" if category_id
    url << "/archive"
    
    records "post", url
  end

  # Create a new message in the given project. The +message+ parameter should
  # be a hash. The +email_to+ parameter must be an array of person-id's that
  # should be notified of the post.
  #
  # If you want to add attachments to the message, the +attachments+ parameter
  # should be an array of hashes, where each has has a :name key (optional),
  # and a :file key (required). The :file key must refer to a Basecamp::FileUpload
  # instance.
  #
  #   msg = session.post_message(158141,
  #      { :title => "Requirements",
  #        :body => "Here are the requirements documents you asked for.",
  #        :category_id => 2301121 },
  #      [john.id, martha.id],
  #      [ { :name => "Primary Requirements",
  #          :file => Basecamp::FileUpload.new('primary.doc", File.read('primary.doc')) },
  #        { :file => Basecamp::FileUpload.new('other.doc', File.read('other.doc')) } ])
  def post_message(project_id, message, notify=[], attachments=[])
    prepare_attachments(attachments)
    record "/projects/#{project_id}/msg/create",
      :post => message,
      :notify => notify,
      :attachments => attachments
  end

  # Edit the message with the given id. The +message+ parameter should
  # be a hash. The +email_to+ parameter must be an array of person-id's that
  # should be notified of the post.
  #
  # The +attachments+ parameter, if used, should be the same as described for
  # #post_message.
  def update_message(id, message, notify=[], attachments=[])
    prepare_attachments(attachments)
    record "/msg/update/#{id}",
      :post => message,
      :notify => notify,
      :attachments => attachments
  end

  # Deletes the message with the given id, and returns it.
  def delete_message(id)
    record "/msg/delete/#{id}"
  end

  # Return a list of the comments for the specified message.
  def comments(post_id)
    records "comment", "/msg/comments/#{post_id}"
  end

  # Retrieve a specific comment
  def comment(id)
    record "/msg/comment/#{id}"
  end

  # Add a new comment to a message. +comment+ must be a hash describing the
  # comment. You can add attachments to the comment, too, by giving them in
  # an array. See the #post_message method for a description of how to do that.
  def create_comment(post_id, comment, attachments=[])
    prepare_attachments(attachments)
    record "/msg/create_comment", :comment => comment.merge(:post_id => post_id),
      :attachments => attachments
  end

  # Update the given comment. Attachments follow the same format as #post_message.
  def update_comment(id, comment, attachments=[])
    prepare_attachments(attachments)
    record "/msg/update_comment", :comment_id => id,
      :comment => comment, :attachments => attachments
  end

  # Deletes (and returns) the given comment.
  def delete_comment(id)
    record "/msg/delete_comment/#{id}"
  end

  # =========================================================================
  # TODO LISTS AND ITEMS
  # =========================================================================

  # Marks the given item completed.
  def complete_item(id)
    record "/todos/complete_item/#{id}"
  end

  # Marks the given item uncompleted.
  def uncomplete_item(id)
    record "/todos/uncomplete_item/#{id}"
  end

  # Creates a new to-do item.
  def create_item(list_id, content, responsible_party=nil, notify=true)
    record "/todos/create_item/#{list_id}",
      :content => content, :responsible_party => responsible_party,
      :notify => notify
  end

  # Creates a new list using the given hash of list metadata.
  def create_list(project_id, list)
    record "/projects/#{project_id}/todos/create_list", list
  end

  # Deletes the given item from it's parent list.
  def delete_item(id)
    record "/todos/delete_item/#{id}"
  end

  # Deletes the given list and all of its items.
  def delete_list(id)
    record "/todos/delete_list/#{id}"
  end

  # Retrieves the specified list, and all of its items.
  def get_list(id)
    record "/todos/list/#{id}"
  end

  # Return all lists for a project. If complete is true, only completed lists
  # are returned. If complete is false, only uncompleted lists are returned.
  def lists(project_id, complete=nil)
    records "todo-list", "/projects/#{project_id}/todos/lists", :complete => complete
  end

  # Repositions an item to be at the given position in its list
  def move_item(id, to)
    record "/todos/move_item/#{id}", :to => to
  end

  # Repositions a list to be at the given position in its project
  def move_list(id, to)
    record "/todos/move_list/#{id}", :to => to
  end

  # Updates the given item
  def update_item(id, content, responsible_party=nil, notify=true)
    record "/todos/update_item/#{id}",
      :item => { :content => content }, :responsible_party => responsible_party,
      :notify => notify
  end

  # Updates the given list's metadata
  def update_list(id, list)
    record "/todos/update_list/#{id}", :list => list
  end

  # =========================================================================
  # MILESTONES
  # =========================================================================

  # Complete the milestone with the given id
  def complete_milestone(id)
    record "/milestones/complete/#{id}"
  end

  # Create a new milestone for the given project. +data+ must be hash of the
  # values to set, including +title+, +deadline+, +responsible_party+, and
  # +notify+.
  def create_milestone(project_id, data)
    create_milestones(project_id, [data]).first
  end

  # As #create_milestone, but can create multiple milestones in a single
  # request. The +milestones+ parameter must be an array of milestone values as
  # descrbed in #create_milestone.
  def create_milestones(project_id, milestones)
    records "milestone", "/projects/#{project_id}/milestones/create", :milestone => milestones
  end

  # Destroys the milestone with the given id.
  def delete_milestone(id)
    record "/milestones/delete/#{id}"
  end

  # Returns a list of all milestones for the given project, optionally filtered
  # by whether they are completed, late, or upcoming.
  def milestones(project_id, find="all")
    records "milestone", "/projects/#{project_id}/milestones/list", :find => find
  end

  # Uncomplete the milestone with the given id
  def uncomplete_milestone(id)
    record "/milestones/uncomplete/#{id}"
  end

  # Updates an existing milestone.
  def update_milestone(id, data, move=false, move_off_weekends=false)
    record "/milestones/update/#{id}", :milestone => data,
      :move_upcoming_milestones => move,
      :move_upcoming_milestones_off_weekends => move_off_weekends
  end

  # Make a raw web-service request to Basecamp. This will return a Hash of
  # Arrays of the response, and may seem a little odd to the uninitiated.
  def request(path, parameters = {}, second_try = false)
    response = post(path, convert_body(parameters), "Content-Type" => content_type)

    if response.code.to_i / 100 == 2
      result = XmlSimple.xml_in(response.body, 'keeproot' => true,
        'contentkey' => '__content__', 'forcecontent' => true)
      typecast_value(result)
    elsif response.code == "302" && !second_try
      connect!(@url, !@use_ssl)
      request(path, parameters, true)
    else
      raise "#{response.message} (#{response.code})"
    end
  end

  # A convenience method for wrapping the result of a query in a Record
  # object. This assumes that the result is a singleton, not a collection.
  def record(path, parameters={})
    result = request(path, parameters)
    (result && !result.empty?) ? Record.new(result.keys.first, result.values.first) : nil
  end

  # A convenience method for wrapping the result of a query in Record
  # objects. This assumes that the result is a collection--any singleton
  # result will be wrapped in an array.
  def records(node, path, parameters={})
    result = request(path, parameters).values.first or return []
    result = result[node] or return []
    result = [result] unless Array === result
    result.map { |row| Record.new(node, row) }
  end

  private

    def connect!(url, use_ssl)
      url = url.sub(/https?:\/\//, '').chomp('/')
      @use_ssl = use_ssl
      @url = url
      @connection = Net::HTTP.new(url, use_ssl ? 443 : 80)
      @connection.use_ssl = @use_ssl
      @connection.verify_mode = OpenSSL::SSL::VERIFY_NONE if @use_ssl
    end

    def convert_body(body)
      body = use_xml ? body.to_xml : body.to_yaml
    end

    def content_type
      use_xml ? "application/xml" : "application/x-yaml"
    end

    def post(path, body, header={})
      request = Net::HTTP::Post.new(path, header.merge('Accept' => 'application/xml'))
      request.basic_auth(@user_name, @password)
      @connection.request(request, body)
    end

    def store_file(contents)
      response = post("/upload", contents, 'Content-Type' => 'application/octet-stream',
        'Accept' => 'application/xml')

      if response.code == "200"
        result = XmlSimple.xml_in(response.body, 'keeproot' => true, 'forcearray' => false)
        return result["upload"]["id"]
      else
        raise "Could not store file: #{response.message} (#{response.code})"
      end
    end

    def typecast_value(value)
      case value
      when Hash
        if value.has_key?("__content__")
          content = translate_entities(value["__content__"]).strip
          case value["type"]
          when "integer"  then content.to_i
          when "boolean"  then content == "true"
          when "datetime" then Time.parse(content)
          when "date"     then Date.parse(content)
          else                 content
          end
        # a special case to work-around a bug in XmlSimple. When you have an empty
        # tag that has an attribute, XmlSimple will not add the __content__ key
        # to the returned hash. Thus, we check for the presense of the 'type'
        # attribute to look for empty, typed tags, and simply return nil for
        # their value.
        elsif value.keys == %w(type)
          nil
        elsif value["nil"] == "true"
          nil
        # another special case, introduced by the latest rails, where an array
        # type now exists. This is parsed by XmlSimple as a two-key hash, where
        # one key is 'type' and the other is the actual array value.
        elsif value.keys.length == 2 && value["type"] == "array"
          value.delete("type")
          typecast_value(value)
        else
          value.empty? ? nil : value.inject({}) do |h,(k,v)|
            h[k] = typecast_value(v)
            h
          end
        end
      when Array
        value.map! { |i| typecast_value(i) }
        case value.length
        when 0 then nil
        when 1 then value.first
        else value
        end
      else
        raise "can't typecast #{value.inspect}"
      end
    end

    def translate_entities(value)
      value.gsub(/&lt;/, "<").
            gsub(/&gt;/, ">").
            gsub(/&quot;/, '"').
            gsub(/&apos;/, "'").
            gsub(/&amp;/, "&")
    end

    def prepare_attachments(list)
      (list || []).each do |data|
        upload = data[:file]
        id = store_file(upload.content)
        data[:file] = { :file => id,
                        :content_type => "application/octet-stream",
                        :original_filename => upload.filename }
      end
    end
end

# A minor hack to let Xml-Simple serialize symbolic keys in hashes
class Symbol
  def [](*args)
    to_s[*args]
  end
end

class Hash
  def to_xml
    XmlSimple.xml_out({:request => self}, 'keeproot' => true, 'noattr' => true)
  end
end
