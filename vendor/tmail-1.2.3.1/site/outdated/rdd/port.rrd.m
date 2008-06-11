= Port Classes

== class TMail::Port

j
TMail::Port は TMail ライブラリでのファイルや文字列の抽象表現です。
メール一通分にあたるリソースを隠蔽します。
e
TMail::Port is the abstruction of mail source.
.

=== Instance Methods

: ropen -> IO
j
    読みこみ用ストリームを返します。
e
    opens stream for read.
.

: wopen -> IO
j
    書きこみ用ストリームを返します。
e
    opens stream for write.
.

: aopen -> IO
j
    追加書きこみ用ストリームを返します。
e
    opens stream for adding.
.

== class TMail::FilePort < TMail::Port

=== Class Methods

: new(filename) -> TMail::FilePort
    filename: String

j
    FilePort オブジェクトを生成します。
    filename はメール一通をおさめたファイル名でなければいけません。
e
    creates new TMail::FilePort object.
.

: filename -> String
j
    このポートが隠蔽しているファイル名を返します。
e
    returns file name which this port is wrapping.
.

== class TMail::StringPort < TMail::Port

=== Class Methods

: new(src = '') -> TMail::StringPort
    src: String

j
    StringPort オブジェクトを生成します。
    string はメール一通分の文字列でなければいけません。
e
    creates new TMail::StringPort object from
    mail source string.
.
