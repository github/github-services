= module TMail

== Module Functions

: new_boundary -> String
j
    新しいバウンダリを作成して返します。
e
    creates new MIME multipart mail boundary.
.

: new_message_id(fqdn = Socket.gethostname) -> String
    fqdn: String

j
    新しいメッセージ ID を作成して返します。
    引数 fqdn が省略された場合はローカルホストの名前を使います。
    一方 fqdn を指定する場合はダイヤルアップであるなどの事情により
    ホストの名前を変える必要があるのだとみなし、それに '.tmail' を
    つけたドメインを使用します。これは「本物の」ドメインで作成される
    メッセージ ID との重複を避けるためです。
e
    creates new message ID.
.

: message_id?(str) -> true | false
    str: String

j
    str がメッセージ ID を含むとき真。
e
    returns true if STR includes message ID string.
.
