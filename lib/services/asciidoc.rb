class Service::Asciidoc < Service
  self.title = 'Asciidoc'
	string     :server
	white_list :server
	default_events :push

  url "https://github.com/edusantana/asciidoc-server/blob/master/python-cgi/README.asciidoc"
#TODO  logo_url "http://myservice.com/logo.png"

	maintained_by :github => 'edusantana'

  supported_by :web => 'http://150.165.237.17/books/edusantana/producao-computacao-ead-ufpb/livro/livro.chunked/index.html',
    :email => 'eduardo.ufpb+asciidoc@gmail.com'

  def receive_push

		# TODO add authencation
		http_post data['server'], :repositorio=> payload['repository']['url'],:payload=>JSON.generate(payload)

  end
end

#How to test
#bundle exec ruby -r config/load.rb -r lib/services/asciidoc.rb -e "Service::Asciidoc.new(:push, {'server'=>'http://localhost/cgi-bin/pull-pdf.py'}).receive_push"
