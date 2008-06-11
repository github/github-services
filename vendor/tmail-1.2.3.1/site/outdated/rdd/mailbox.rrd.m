= Mailbox Classes

== class TMail::MhMailbox

j
MH 形式のメールボックスを隠蔽するクラス。
e
The class to handle MH mailboxes.
.

=== Class Methods

: new(dirname) -> TMail::MhMailbox
    dirname: String

j
    MhMailbox オブジェクトを生成します。
    dirname は MH メールボックスとして使うディレクトリ名です。
    すでに作成ずみでなければいけません。
e
    creates new MhMailbox object.
    DIRNAME must be valid MH mailbox directory.
.

=== Instance Methods

: each_port {|port| .... }
: each {|port| .... }
    port: TMail::FilePort

j
    メールボックスのメールに対して古いメールから順番に繰り返します。
e
    iterates for each mail in the mailbox,
    in assendant order (older mail first).
.

: reverse_each_port {|port| .... }
: reverse_each {|port| .... }
    port: TMail::FilePort

j
    ディレクトリ中のメールに対して新しいメールから順番に繰り返します。
e
    iterates for each mail in the mailbox,
    in descendant order (newer mail first).
.

: last_atime -> Time
: last_atime=(time)
    time: Time

j
    最後に each_new_port/each_port/reverse_each_port を呼び出した時間。
e
    The time which last each_new_port/each_port/reverse_each_port is called.
.

: each_new_port(time = last_atime()) {|port| .... }
    time: Time
    port: TMail::FilePort

j
    新着メールのみに対してくりかえします。
    引数 time が与えられたときはその時刻以降に更新されたメールを新着とみなします。
    与えられなかった時は前回の each_mail, reverse_each_mail, each_new_port の後に
    更新されたメールを新着とみなします。
e
    iterates for each mails in mailbox, which are newer than TIME.
.

: new_port -> TMail::FilePort
j
    新しいメールに対応するファイルを作成し、
    対応する TMail::Port オブジェクトを返す。
e
    creates a new file in the mailbox and returns its port.
.

: close
j
    なにもしません。
e
    does nothing.
.

== class TMail::UNIXMbox

j
UNIX mbox を扱うクラス。現在の実装では、生成時に MH 形式に変換し、
明示的な close 呼び出しか GC のタイミングでファイルに書き戻します。
e
The class to handle UNIX mbox.
Current implementation creates temporary MH mbox.
.

=== Class Methods

: new(filename) -> TMail::UNIXMbox
    filename: String

j
    新しい TMail::UNIXMbox オブジェクトを生成します。
    filename は UNIX mbox ファイル名です。
e
    creates new TMail::UNIMbox object.
    FILENAME must be valid UNIX mbox file name.
.

=== Instance Methods

: each_port {|port| .... }
: each {|port| .... }
    port: TMail::FilePort

j
    メールボックスのメールに対して古いメールから順番に繰り返します。
e
    iterates for each mail in the mailbox,
    in assendant order (older mail first).
.

: reverse_each_port {|port| ... }
: reverse_each {|port| ... }
    port: TMail::FilePort

j
    ディレクトリ中のメールに対して新しいメールから順番に繰り返します。
e
    iterates for each mail in the mailbox,
    in descendant order (newer mail first).
.

: each_new_port(time = @last_loaded_time) {|port| .... }
    time: Time
    port: TMail::FilePort

j
    新着メールのみに対してくりかえします。
    引数 time が与えられたときはその時刻以降に更新されたメールを新着とみなします。
    与えられなかった時は前回の each_mail, reverse_each_mail, each_new_port の後に
    更新されたメールを新着とみなします。
e
    iterates for each mails in mailbox, which are newer than TIME.
    @last_loaded_time is updated when each_new_port/each_port is
    called.
.

: new_port -> TMail::FilePort
j
    新しいメールに対応するファイルを作成し、
    対応する TMail::Port オブジェクトを返す。
e
    creates a new file in the mailbox and returns its port.
.

: close
j
    明示的にメールボックスを書き戻します。以後、このオブジェクトに
    対してメール操作メソッドを呼び出すと全て例外になります。
e
    forces an UNIXMbox to write back mails to real mbox file.
    Once this method is called, any method calls causes to raise
    IOError exception.
.

== class TMail::Maildir

j
qmail が使用するメールボックス maildir を隠蔽するクラス。
e
The class to handle "maildir" mailbox.
.

=== Class Methods

: new(dirname) -> TMail::Maildir
    dirname: String

j
    新しい TMail::Maildir オブジェクトを生成します。
    dirname は maildir メールボックスとして使うディレクトリ名です。
    ディレクトリはすでに作成ずみでなければいけません。
e
    creates new TMail::Maildir object.
    DIRNAME must be valid maildir.
.

=== Instance Methods

: each_port {|port| .... }
: each {|port| .... }
    port: TMail::FilePort

j
    メールボックスのメールに対して古いメールから順番に繰り返します。
e
    iterates for each mail in the mailbox,
    in assendant order (older mail first).
.

: reverse_each_port {|port| .... }
: reverse_each {|port| .... }
    port: TMail::FilePort

j
    ディレクトリ中のメールに対して新しいメールから順番に繰り返します。
e
    iterates for each mail in the mailbox,
    in descendant order (newer mail first).
.

: each_new_port {|port| .... }
    port: TMail::FilePort

j
    MAILDIR/new のメールに対して、cur に移動したのちに繰り返します。
e
    iterates for each mails in MAILDIR/new.
.

: new_port -> TMail::FilePort
j
    新しいメールに対応するファイルを作成し、
    対応する Port オブジェクトを返す。
e
    creates a new file in the mailbox and returns its port.
.
