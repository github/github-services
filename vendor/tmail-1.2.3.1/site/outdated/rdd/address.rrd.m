= Address Classes

== class TMail::Address

=== Class Methods

: parse(str)  ->  TMail::Address | TMail::AddressGroup
    str: String

j
    文字列 str から TMail::Address または TMail::AddressGroup
    オブジェクトを生成します。str がメールアドレスとみなせない
    ときは例外 TMail::SyntaxError を発生します。
e
    parses STR and creates new 'TMail::Address' object.
    If STR did not follow the internet address format,
    'TMail::SyntaxError' exception is raised.
.

: new(locals, domains)  ->  TMail::Address | TMail::AddressGroup
    locals: [String]
    domains: [String]

j
    新しい TMail::Address オブジェクトを生成します。locals、domains はそれぞれ
    アドレススペック (...@...) の、＠の左側と右側をドットで split した
    配列です。このメソッドは内部用であり使いにくくなっています。
    Address.parse を使ってください。
e
    creates new 'TMail::Address' object consist from local part
    LOCALS and domain part DOMAINS.
.

=== Instance Methods

: address_group?  ->  true | false
j
    常に false
e
    returns false.
.

: spec -> String
j
    アドレススペック文字列 ("....@....")。
e
    an address spec ("....@....").
.

: routes -> [String]
j
    配送経路を表す文字列の配列。'@' は含まない。
e
    delivery routes. Strings do not include character "@".
.

: name -> String
: phrase -> String
j
    俗に言うアドレスの「本名」部分。デコードされています。
e
    short description for this address (e.g. real name).
.

: encoded(eol = "\r\n", encoding = 'j') -> String
    eol: String
    encoding: String

j
    B エンコードされた RFC2822 形式の文字列表現を返します。
    行末コードに eol、文字エンコーディングに encoding を使います。
    ただし encoding は j しか実装されていません。
e
    converts this object into MIME-encoded string.
.

: to_s(eol = "\n", encoding = 'e') -> String
: decoded(eol = "\n", encoding = 'e') -> String
    eol: String
    encoding: String

j
    デコードされた RFC2822 形式の文字列表現を返します。
    行末コードに eol、文字エンコーディングに encoding を使います。
e
    converts this object into decoded string.
.

: ==(other) -> true | false
    other: Object

j
    spec の同値判定によって self と other が等しいか判定します。
    name や routes は影響しません。
e
    judge if self equals to other by inspecting addr-spec string (#spec).
    #name and #routes never affects the return value.
.


== class TMail::AddressGroup

=== Class Methods

: new(name, addrs) -> TMail::AddressGroup
    name: String
    addrs: [TMail::Address | TMail::AddressGroup]

j
    新しい TMail::AddressGroup オブジェクトを作成します。
    name はグループ名を示す文字列、addrs は TMail::Address または
    TMail::AddressGroup の配列でなければいけません。
e
    creates new 'TMail::AddressGroup' object.
    NAME is the name of this group, ADDRS is addresses
    which belongs to this group.
.

=== Instance Methods

: address_group?  ->  true | false
j
    常に true
e
    returns true.
.

: name -> String
j
    グループ名。
e
    the human readable name of this group.
.

: addresses -> [TMail::Address | TMail::AddressGroup]
j
    TMail::Address または TMail::AddressGroup オブジェクトの配列。
e
    addresses which belongs to this group.
.

: to_a -> [TMail::Address | TMail::AddressGroup]
: to_ary -> [TMail::Address | TMail::AddressGroup]
j
    addresses.dup と同じです。
e
    equals to 'addresses.dup'.
.

: flatten -> [TMail::Address]
j
    再帰的に TMail::AddressGroup オブジェクトを平坦化し、
    TMail::Address オブジェクトの配列を得ます。
e
    flatten this group into one level of array of 'TMail::Address'.
.

: add(addr)
: push(addr)
    addr: TMail::Address | TMail::AddressGroup

j
    TMail::Address または TMail::AddressGroup オブジェクトを
    このグループに追加します。
e
    adds an address or an address group to this group.
.

: delete(addr)
    addr: TMail::Address | TMail::AddressGroup

j
    TMail::Address または TMail::AddressGroup オブジェクトを
    このグループから削除し、非 nil を返します。もともとこの
    アドレスがグループ内に存在しない場合は無視して nil を返します。
e
    removes ADDR from this group.
.

: each {|a| .... }
    a: TMail::Address | TMail::AddressGroup

j
    #addresses に対する繰り返し。
e
    equals to 'addresses.each {|a| .... }'.
.

: each_address {|a| .... }
    a: TMail::Address

j
    #addresses に対する繰り返し。ただし TMail::AddressGroup オブジェクトに
    対しては内部に入って再帰的に繰り返します。
e
    equals to 'flatten.each {|a| .... }'
.

: encoded(eol = "\r\n", encoding = 'j')  ->  String
    eol: String
    encoding: String

j
    ,B エンコードされた ,RFC2822 形式の文字列表現を返します。
e
    converts this object into MIME-encoded string.
.

: decoded(eol = "\n", encoding = 'e')  ->  String
    eol: String
    encoding: String

j
    デコードされた RFC2822 形式の文字列表現を返します。
e
    converts this object into decoded string.
.

: ==(other)    ->  true | false
: eql?(other)  ->  true | false
    other: Object

j
    #addresses の同値判定によって同じ内容かどうかを判断します。
    #name は影響しません。
e
    judges if self is equal to OTHER, by comparing 'self.addresses' and
    'other.addresses'. ('self.name' is meanless)
.
