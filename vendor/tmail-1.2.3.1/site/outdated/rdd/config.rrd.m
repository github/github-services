= class TMail::Config

== Class Methods

: new(strict) -> TMail::Config
    strict: true | false

j
    TMail::Config オブジェクトを生成します。strict が真の場合、
    生成された Config オブジェクトのすべての strict_* フラグを
    オンにします。
e
    create a TMail::Config object.
    set true to all strict_* attributes if STRICT is true.
.

== Instance Methods

: strict_parse?
j
    真ならば TMail のパーサはヘッダパース中に発生した
    TMail::SyntaxError を返します。
e
    If this flag is true, TMail's parsers may raise
    TMail::SyntaxError. If not, it never raises SynaxError.
.
