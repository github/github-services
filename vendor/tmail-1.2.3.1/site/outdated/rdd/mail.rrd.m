@nocode MH
= class TMail::Mail

== Class Methods

: new(port = TMail::StringPort.new, config = DEFAULT_CONFIG) -> TMail::Mail
    port: TMail::Port
    config: TMail::Config

j
    port から Mail オブジェクトを作成します。
e
    creates a new 'TMail::Mail' object from PORT.
.

: load(filename) -> TMail::Mail
    filename: String

j
    ファイル filename からメールをロードして Mail オブジェクトを作成します。
    ロードするファイルは MH のメールのようにメール一通がファイルひとつに
    対応していなければいけません。

    ,UNIX mbox のような形式は単独では対応していません。
    <a href="mbox.html">メールボックスクラス</a>を使ってください。
e
    creates a new 'TMail::Mail' object. FILENAME is the name of file
    which contains just one mail (e.g. MH mail file).
.

: parse(str) -> TMail::Mail
    str: String

j
    文字列 str をパースして TMail::Mail オブジェクトを作成します。
    str はメール一通分でなければいけません。
e
    parses STR and creates a new 'TMail::Mail' object.
.

== Instance Methods

: port -> TMail::Port
j
    このメールオブジェクトの生成元のポートです。
e
    the source port of this mail.
.

: body_port -> TMail::Port
j
    メール本文を保存しているポートを返します。

    ただしここに書きこんでもロード元のファイル(や文字列)は変更されません。
    実際に変更するためにはこのポートに書きこんだ後 #write_back を呼ぶ
    必要があります。
e
    the port to save body of this mail.
.

: each {|line| .... }
    line: String

j
    本文文字列の各行に対する繰り返し。
    body_port.ropen {|f| f.each } と同じです。
e
    iterates for each lines of mail body.
.

: body -> String
: preamble -> String
j
    メールボディ(本文)全てを文字列として返します。
    MIME マルチパートメールのときは preamble に相当します。
    この返り値を変更してもオリジナルは変更されません。
e
    the mail body. If the mail is a MIME multipart mail,
    this attribute represents "preamble".
.

: parts -> [TMail::Mail]
j
    メールが MIME マルチパートメールの時、各パートが TMail::Mail の配列として
    格納されています。マルチパートメールでないときは空の配列です。

    ただしここに書きこんでもロード元のファイル(や文字列)は変更されません。
    実際に変更するためにはこのオブジェクトに書きこんだあと #write_back を
    呼ぶ必要があります。
e
    parts of this mail. (valid only if this mail is a MIME multipart mail)
.

: epilogue -> String
j
    MIME マルチパートメールでの epilogue に相当する文字列です。
    通常のメールのときは空文字列が入っています。

    ただしここに書きこんでもロード元のファイル(や文字列)は変更されません。
    実際に変更するためには書きこんだ後 #write_back を呼ぶ必要があります。
e
    If the mail was MIME multipart mail, this represent "epilogue" string.
    Else, empty string.
.

: multipart?
j
    メールが MIME マルチパートのとき真。
    このメソッドは Content-Type ヘッダの内容で真偽を判断します。
e
    true if the message is a multi-part mail.
.

: encoded(eol = "\n", encoding = 'j') -> String
    eol: String
    encoding: String

j
    メールを RFC2822 形式にエンコードした文字列に変換します。
    その際、ヘッダの行末コードを eol に、ヘッダ内のエンコード前の
    日本語文字列の文字コードを encoding に変換します。
    ただし現在 encoding は "j" (JIS) しか正常に動作しません。

    バージョン 0.9 からは #to_s は #decoded の別名になったので、この
    メソッドとは違うはたらきをします。
e
    converts the mail object to a MIME encoded string.
.

: decoded(eol = "\n", encoding = 'e') -> String
: to_s(eol = "\n", encoding = 'e') -> String
    eol: String
    encoding: String

j
    メールをデコードされた文字列に変換します。その際、ヘッダの行末
    コードを eol に、ヘッダ内のエンコード前の日本語文字列の文字コードを
    encoding に変換します。

    バージョン 0.9 以降は #to_s はこのメソッドの別名になりました。
e
    converts the mail object to a decoded string.
.

: inspect -> String
j
    以前は #decoded の別名でしたがバージョン 0.9 からは
    "#<TMail::Mail port=<StringPort:str=...>>"
    のような簡潔な文字列化を行います。
e
    returns simple string representation like
    '"#<TMail::Mail port=<StringPort:str=...>>"'
.

: write_back(eol = "\n", encoding = 'e')
    eol: String
    encoding: String

j
    メール全体を文字列化し body_port に書き戻します。その際、ヘッダの
    行末コードを eol に、ヘッダ内の日本語文字列の文字コードを encoding に
    変換します。
e
    converts this mail into string and write back to 'body_port',
    setting line terminator to EOL.
.

j
=== 属性アクセスのためのメソッド
e
=== Property Access Method
.

: date(default = nil) -> Time
: date=(datetime)
    datetime: Time
    default: Object

j
    Date: ヘッダに対応する Time オブジェクト。
    常にローカルタイムに変換されます。
e
    a Time object of Date: header field.
.

: strftime(format, default = nil) -> String
    format: String
    default: Object

j
    Date: ヘッダに表現された時刻と対応する Time オブジェクトに対し
    strftime を呼びます。Date: ヘッダが存在しない場合は default を
    返します。
e
    is equals to 'date.strftime(format)'.
    If date is not exist, this method does nothing and
    returns DEFAULT.
.

: to(default = nil)  ->  [String]
: to=(specs)
    specs: String | [String]
    default: Object

j
    To: アドレスの spec の配列。
e
    address specs for To: header field.
.

: to_addrs(default = nil)  ->  [TMail::Address | TMail::AddressGroup]
: to_addrs=(addrs)
    addrs: TMail::Address | [TMail::Address]
    default: Object

j
    To: アドレスの配列。
e
    adresses which is represented in To: header field.
.

: cc(default = nil)  ->  [String]
: cc=(specs)
    specs: String | [String]
    default: Object

j
    Cc: アドレスの spec の配列。
e
    address specs for Cc: header field.
.

: cc_addrs(default = nil)  ->  [TMail::Address]
: cc_addrs=(addrs)
    addrs: TMail::Address | [TMail::Address]
    default: Object

j
    Cc: アドレスの配列。
e
    addresses which is represented in Cc: header field.
.

: bcc(default = nil)  ->  [String]
: bcc=(specs)
    specs: String | [String]
    default: Object

j
    Bcc: アドレスの spec の配列。
e
    address specs for Bcc: header field.
.

: bcc_addrs(default = nil) -> [TMail::Address]
: bcc_addrs=(addrs)
    addrs: TMail::Address | [TMail::Address]
    default: Object

j
    Bcc: アドレスの配列。
e
    adresses which is represented in Bcc: header field.
.

: from(default = nil) -> [String]
: from=(specs)
    specs: String | [String]
    default: Object

j
    From: アドレスの spec の配列。
e
    address specs for From: header field.
.

: from_addrs(default = nil) -> [TMail::Address]
: from_addrs=(addrs)
    addrs: TMail::Address | [TMail::Address]
    default: Object

j
    From: アドレスの配列。
e
    adresses which is represented in From: header field.
.

: friendly_from(default = nil) -> String
    default: Object

j
    From: の最初のアドレスの phrase または spec。
    From: が存在しないときは default を返します。
e
    a "phrase" part or address spec of the first From: address.
.

: reply_to(default = nil) -> [String]
: reply_to=(specs)
    specs: String | [String]
    default: Object

j
    Reply-To: アドレスの spec の配列。
e
    address specs of Reply-To: header field.
.

: reply_to_addrs(default = nil) -> [TMail::Address]
: reply_to_addrs=(addrs)
    addrs: TMail::Address | [TMail::Address]
    default: Object

j
    Reply-To: アドレスの配列。
e
    adresses which is represented in Reply-To: header field.
.

: sender(default = nil) -> String
: sender=(spec)
    spec: String

j
    Sender: アドレスの spec
e
    address spec for Sender: header field.
.

: sender_addr(default = nil) -> TMail::Address
: sender_addr=(addr)
    addr: TMail::Address

j
    Sender: アドレス
e
    an address which is represented in Sender: header field.
.

: subject(default = nil) -> String
: subject=(sbj)
    sbj: String

j
    Subject: の内容。
    Subject: が存在しないときは default を返します。
e
    the subject of the message.
.

: message_id(default = nil) -> String
: message_id=(id)
    id: String

j
    メールのメッセージ ID。
e
    message ID string.
.

: in_reply_to(default = nil) -> [String]
: in_reply_to=(ids)
    ids: String | [String]

j
    In-Reply-To: に含まれるメッセージ ID のリスト。
e
    message IDs of replying mails.
.

: references(default = nil) -> [String]
: references=(ids)
    ids: String | [String]

j
    References: に含まれるメッセージ ID のリスト。
    現在は References: にはメッセージ ID 以外は
    含められません。(RFC2822)
e
    message IDs of all referencing (replying) mails.
.

: mime_version(default = nil) -> String
: mime_version=(ver)
    ver: String

j
    MIME バージョン。現在は常に "1.0" です。
    ヘッダが存在しない場合は default を返します。
e
    MIME version.
    If it does not exist, returns the DEFAULT.
.

: set_mime_version(major, minor)
    major: Integer
    minor: Integer

j
    MIME バージョンをセットします。
e
    set MIME version from integers.
.

: content_type(default = nil) -> String
j
    メール本体のファイルタイプを示す文字列。例えば "text/plain"。
    ヘッダが存在しない場合は default を返します。
e
    the content type of the mail message (e.g. "text/plain").
    If it does not exist, returns the DEFAULT.
.

: main_type(default = nil) -> String
j
    メール本体のメインタイプ (例："text")。
    常に小文字に統一されます。
    ヘッダが存在しない場合は default を返します。
e
    the main content type of the mail message. (e.g. "text")
    If it does not exist, returns the DEFAULT.
.

: sub_type(default = nil) -> String
j
    メール本体のサブタイプ (例："plain")。
    常に小文字に統一されます。
    ヘッダが存在しない場合は default を返します。
e
    the sub content type of the mail message. (e.g. "plain")
    If it does not exist, returns the DEFAULT.
.

: content_type=(ctype)
    ctype: String

j
    Content-Type のメインタイプ・サブタイプを main_sub からセット
    します。main_sub は例えば "text/plain" のような形式でなければ
    いけません。
e
    set content type to STR.
.

: set_content_type(main, sub, params = nil)
    main: String
    sub: String
    params: {String => String}

j
    コンテントタイプを main/sub; param; param; ... のように設定します。
e
    set Content-type: header as "main/sub; param=val; param=val; ...".
.

: type_param(name, default = nil) -> String
    name: String

j
    Content-Type の name パラメータの値を返します。
    name に対応する値やヘッダそのものが存在しない場合は default を
    返します。
e
    returns the value corresponding to the case-insensitive
    NAME of Content-Type parameter.
    If it does not exist, returns the DEFAULT.
.
      --
      # example
      mail['Content-Type'] = 'text/plain; charset=iso-2022-jp'
      p mail.type_param('charset')   # "iso-2022-jp"
      --

: multipart? -> true | false
j
    Content-Type が MIME マルチパートメールであることを
    示す内容ならば真。
e
    judge if this mail is MIME multi part mail,
    by inspecting Content-Type: header field.
.

: transfer_encoding(default = nil) -> String
: transfer_encoding=(encoding)
    encoding: String
j
    転送時に適用したエンコーディング (Content-Transfer-Encoding)。
    '7bit' '8bit' 'Base64' 'Binary' など。
e
    Content-Transfer-Encoding. (e.g. "7bit" "Base64")
.

: disposition(default = nil) -> String
: disposition=(pos)
    pos: String

j
    Content-Disposition の主値 (文字列)。返り値は常に小文字に統一されます。
    name に対応する値やヘッダそのものが存在しない場合は default を
    返します。
e
    Content-Disposition main value (e.g. "attachment").
    If it does not exist, returns the DEFAULT.
.
      --
      # example
      mail['Content-Disposition'] = 'attachement; filename="test.rb"'
      p mail.disposition   # "attachment"
      --

: set_content_disposition(pos, params = nil)
    pos: String
    params: {String => String}

j
    disposition 文字列とパラメータのハッシュから Content-Disposition を
    セットします。
e
    set content disposition.
.

: disposition_param(key, default = nil) -> String
    key: String

j
    Content-Disposition の付加パラメータの name の値を取得します。
    name に対応する値やヘッダそのものが存在しない場合は default を
    返します。
e
    returns a value corresponding to the Content-Disposition
    parameter NAME (e.g. filename).
    If it does not exist, returns the DEFAULT.
.
      --
      # example
      mail.disposition_param('filename')
      -- 

: destinations(default = nil) -> [String]
j
    To、Cc、Bcc すべてのアドレススペック文字列の配列を
    返します。ひとつも存在しなければ default を返します。
e
    all address specs which are contained in To:, Cc: and
    Bcc: header fields.
.

: reply_addresses(default = nil) -> [TMail::Address]
j
    返信すべきアドレスを判断し、Address オブジェクトの
    配列で返します。返信すべきアドレスがみつからなければ
    DEFAULT を返します。
e
    addresses to we reply to.
.

: error_reply_addresses(default = nil) -> [TMail::Address]
j
    エラーメールを返送すべきアドレスを判断し、Address オブジェクトの
    配列で返します。返送すべきアドレスがみつからなければ default を返します。
e
    addresses to use when returning error message.
.

j
=== ヘッダフィールド直接操作用メソッド
e
=== Direct Header Handling Methods
.

: clear
j
    ヘッダを全て消去します。
e
    clears all header.
.

: keys -> [TMail::HeaderField]
j
    ヘッダ名の配列を返します。
e
    returns an array of contained header names.
.

: [](name) -> TMail::HeaderField
    name: String

j
    ヘッダ名からヘッダオブジェクトを返します。
e
    returns a header field object corresponding to the case-insensitive
    key NAME. e.g. mail["To"]
.

: []=(name, field)
    name: String
    field: TMail::HeaderField

j
    name ヘッダに field を設定します。field は文字列か TMail::HeaderField オブジェクトです。
    Received など一部のヘッダに対してはさらにその配列も与えることができます。
e
    set NAME header field to FIELD.
.

: delete(name)
    name: String
j
    name ヘッダを消します。
e
    deletes header corresponding to case-insensitive key NAME.
.

: delete_if {|name, field| .... }
    name: String
    field: TMail::HeaderField

j
    ヘッダ名とヘッダを与えてブロックを評価し、真ならその関連づけを消します。
e
    evaluates block with a name of header and header field object,
    and delete the header if block returns true.
.

: each_header {|name, field| .... }
: each_pair {|name, field| .... }
    name: String
    field: TMail::HeaderField

j
    全てのヘッダ名とヘッダオブジェクトに対するくりかえし。
e
    iterates for each header name and its field object.
.

: each_header_name {|name| .... }
: each_key {|name| .... }
    name: String

j
    全てのヘッダ名に対するくりかえし。
e
    iterates for each contained header names.
.

: each_field {|field| .... }
: each_value {|field| .... }
    field: TMail::HeaderField

j
    全てのヘッダオブジェクトに対するくりかえし。
e
    iterates for each header field objects.

: orderd_each {|name, field| .... }
    name: String
    field: TMail::HeaderField

j
    ヘッダの順序指定付きの each_header です。最初に指定したものが指定した
    順番で並び、その他のヘッダがランダムに続きます。順序は文字列の配列
    TMail::Mail::FIELD_ORDER で設定してください(詳細はソースコードを参照)。
e
    iterates for each header field objects, in canonical order.
.

: key?(name)
    name: String

j
    name ヘッダがあれば真。
e
    returns true if the mail has NAME header.
.

: value?(field)
    field: TMail::HeaderField

j
    field ヘッダオブジェクトがあれば真。
e
    returns true if the mail has FIELD header field object.
.

: values_at(*names) -> [TMail::HeaderField]
: indexes(*names) -> [TMail::HeaderField]
: indices(*names) -> [TMail::HeaderField]
    names: [String]

j
    全ての names について fetch した結果の配列を返します。
e
    equals to 'names.collect {|k| mail[k] }'.
.

: values -> [TMail::HeaderField]
j
    登録されている全てのヘッダオブジェクトの配列を返します。
e
    returns an array of all header field object.
.
