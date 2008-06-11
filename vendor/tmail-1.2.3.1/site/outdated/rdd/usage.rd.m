j
= TMail の使い方
e
= TMail Usage
.

j
== TMail の概要
e
== Abstruction
.

j
TMail は電子メールを扱うための総合ライブラリです。メールとメール
ボックスのハンドリングを隠蔽します。初期の目的がメーラの作成だった
ため、主な使い方としては「メールから情報を得る」「新しいメールを作成する」
の二種類が想定されており、クライアント側の処理に強くなっています。
e
TMail is 90% RFC compatible mail library. By using TMail, You can
get data from internet mail (e-mail) and write data to mail,
without knowning standard details.
.

j
== メールから情報を得る

これは一番最初に実装された部分であり、TMail が最も得意とする処理でも
あります。
e
== Getting information from e-mail
.

j
=== TMail::Mail クラス
e
=== class TMail::Mail
.

j
TMail::Mail クラスはメール一通を隠蔽するオブジェクトです。まずどうにか
してこのオブジェクトを作らないといけません。このオブジェクトを作る方法は
三通りあります。

  (1) 文字列からつくる
  (2) ファイル(名)からつくる
  (3) Port からつくる

文字列、ファイルはそれぞれメール一通分だけを含んでいなければいけません。
そのうえで以下のように作成します。
e
At first you must create TMail::Mail object. There's three ways
to create Mail object. First one is "creating from string", second
way is "creating from file (name)". Examples are below:
.
--
require 'tmail'
mail = TMail::Mail.parse(string)    # from String
mail = TMail::Mail.load(filename)   # from file
--
j
ここには特に問題はないと思います。
.

j
=== Port と Loader
e
=== Port and Loader
.

j
Port というのは TMail におけるメールソースの抽象表現です。たとえば
上述した文字列やファイル名もメールソースで、TMail::Mail#parse や load は
文字列やファイルを一度 Port でラップしたうえで Mail オブジェクトを作成
しています。この Port でラップすることで文字列、ファイル
(将来的には IMAP プロトコルも？) の違いを隠蔽しています。

ただし、Port をユーザが直接作ることはあまりないでしょう。主にユーザが
Port をさわることになるのは、メールボックスのラッパーである Loader を
使うときです。たとえば MH メールボックスの中にあるメールを順番に処理する
ためには以下のようにします。
e
The third way to get TMail::Mail object is using the "port".
"port" is the abstruction of mail sources, e.g. strings or file names.
You can get ports by using mail loaders (TMail::*Loader classes).
Here's simple example:
.
--
require 'tmail'

loader = TMail::MhLoader.new( '/home/aamine/Mail/inbox' )
loader.each_port do |port|
  mail = TMail::Mail.new(port)
  # ....
end
--

j
=== TMail::Mail オブジェクトから情報を得る
e
=== Accessing EMail Attributes via TMail::Mail object
.

j
以上のような手段で TMail::Mail オブジェクトを作ったら、あとはそのメソッドを
呼ぶだけでたいていのことはできます。たとえば To: アドレスを取るなら
e
Now you can get any data from e-mail, by calling methods of
TMail::Mail object. For example, to get To: addresses...
.
--
require 'tmail'
mail = TMail::Mail.parse( 'To: Minero Aoki <aamine@loveruby.net>' )
p mail.to   # => ["aamine@loveruby.net"]
--
j
Subject: ならば
e
to get subject,
.
--
p mail.subject
--
j
メール本体ならば
e
to get mail body,
--
p mail.body
--
j
というように、とても簡単です。
.

j
詳しくは TMail::Mail クラスのリファレンスを、
より実用的な例としては sample/from-check.rb を見てください。
e
For more TMail::Mail class details, see reference manual.
For more examples, see sample/from-check.rb.
.

j
=== MIME マルチパートメール

MIME マルチパートメールにも対応しています。マルチパートのときは
Mail#multipart? が真になり、#parts に TMail::Mail オブジェクトの
配列が入ります。
e
=== MIME multipart mail

TMail also supports MIME multipart mails.
If mail is multipart mail, Mail#multipart? returns true,
and Mail#parts contains an array of parts (TMail::Mail object).
.
--
require 'tmail'
mail = TMail::Mail.parse( multipart_mail_string )
if mail.multipart? then
  mail.parts.each do |m|
    puts m.main_type
  end
end
--
j
より具体的な例としては sample/multipart.rb を見てください。
e
For examples, see sample/multipart.rb.
.

j
=== TMail がやらないこと

TMail は、ヘッダは自動でデコード・エンコードしますが、本体(本文)は
一切変更しません。ただし近い将来には Base64 のデコードは自動でやる
かもしれません。
e
=== What TMail is NOT

TMail does not touch mail body. Does not decode body,
does not encode body, does not change line terminator.
(I want to support Base64 auto-decoding although.)
.


j
== 新しいメールを作成する

こちらも TMail::Mail クラスが主体です。とにかくメールを作ればいい
場合は空文字列から、メールボックスに作りたい場合はローダを経由して
ポートを作成してそこから、メールオブジェクトを作ります。
e
== Creating New Mail
.
--
require 'tmail'

# Example 1: create mail on only memory
mail = TMail::Mail.new

# Example 2: create mail on mailbox (on disk)
loader = TMail::MhLoader.new('/home/aamine/Mail/drafts')
mail = TMail::Mail.new( loader.new_port )
--
j
作ったら、中身を入れます。
e
then fill headers and body.
.
--
mail.to = 'test@loveruby.net'
mail.from = 'Minero Aoki <aamine@loveruby.net>'
mail.subject = 'test mail'
mail.date = Time.now
mail.mime_version = '1.0'
mail.set_content_type 'text', 'plain', {'charset'=>'iso-2022-jp'}
mail.body = 'This is test mail.'
--
j
どのヘッダをセットしたらいいかなど細かい部分ももうちょっとカバー
したいのですが、まだ実装していません。とりあえず上記のヘッダは
セットしたほうがよいでしょう。また返信・転送の場合はまたそれぞれ
規約があります。これもカバーしたいのですがまだ実装していません。
バージョン 1.0 に期待してください。

最後に文字列化します。
e
At last, convert mail object to string.
.
--
str = mail.encoded
--
j
作成元ポートに書き戻すなら、かわりに以下のようにします。
e
If you want to write mails against files directly
(without intermediate string), use Mail#write_back.
.
--
mail.write_back
--
j
write_back は中間文字列を介することなくファイルに直接書きこみます。

より実用的な例としては sample/sendmail.rb を見てください。
e
For more examples, see sample/sendmail.rb.
.
